//
//  InitialViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Combine
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class InitialViewController: UIViewController {

    // MARK: - Packdata UI

    @IBOutlet var packdataLabel: UILabel!
    @IBOutlet var packdataStackView: UIStackView!
    @IBOutlet var checkAndDownloadButton: UIButton!

    // MARK: - Common UI

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var sourcePicker: UIPickerView!
    @IBOutlet var onlineSwitch: UISwitch!
    @IBOutlet var onlineLabel: UILabel!
    @IBOutlet var loadMapButton: UIButton!
    @IBOutlet var envLabel: UILabel!
    @IBOutlet var envSwitch: UISwitch!

    private let locationSourceTitles = LocationSourceType.allCases.map(\.name)
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Packdata Properties

    private lazy var packdataManager: PackdataManaging = DependencyManager.getPackdataManager()
    private let fileManager: FileManager = .default
    private let userDefaults: UserDefaults = .standard
    private var packdata: Packdata?

    override func viewDidLoad() {
        super.viewDidLoad()

        sourcePicker.dataSource = self
        sourcePicker.delegate = self

        // uncomment if you want to use dev environment
//        WemapCore.setEnvironment(.dev)
//        WemapCore.setItinerariesEnvironment(.dev)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapIDTextField.text = "\(Constants.mapID)"
        
        // if you need to retrieve all points of interest for some map in advance
//        ServiceFactory
//            .getPointOfInterestService()
//            .pointsOfInterestList(mapID: Constants.mapID)
//            .sink(receiveCompletion: {
//                if case let .failure(error) = $0 {
//                    debugPrint("failed to receive pois with error - \(error)")
//                }
//            }, receiveValue: {
//                debugPrint("received pois - \($0)")
//            })
//            .store(in: &cancellables)

        packdata = loadPackdataIfAvailable()
        if let packdata {
            packdataLabel.text = "Offline packdata (v\(packdata.version))"
            loadMapButton.isEnabled = true
        } else {
            checkAndDownloadButton.setTitle("Download", for: .selected)
            checkAndDownloadButton.isSelected = true
        }
    }

    @IBAction func onlineSwitchToggle() {
        let isSwitchOn = onlineSwitch.isOn
        onlineLabel.text = isSwitchOn ? "Online" : "Offline"
        packdataStackView.isHidden = isSwitchOn
        loadMapButton.isEnabled = isSwitchOn || packdata != nil
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func showMap() {
        
        let locationSourceType = LocationSourceType(rawValue: sourcePicker.selectedRow(inComponent: 0))
        
        let isAvailable = switch locationSourceType {
        case .simulator: SimulatorLocationSource.isAvailable
        case .systemDefault, .none: true
        }
        
        guard isAvailable else {
            return showAlert(message: "Desired location source is unavailable on this device")
        }
        
        loadMap()
    }

    @IBAction func checkForPackdataUpdatesButtonClicked() {
        if checkAndDownloadButton.isSelected {
            downloadNewPackdata()
        } else {
            checkForUpdates()
        }
    }

    @IBAction func envSwitched() {
        let env: Environment = envSwitch.isOn ? .prod : .dev
        envLabel.text = envSwitch.isOn ? "Prod" : "Dev"
        WemapCore.setEnvironment(env)
        WemapCore.setItinerariesEnvironment(env)
        mapIDTextField.text = "\(Constants.mapID)"
    }

    // MARK: - Private

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func getMapID() -> Int? {
        guard let text = mapIDTextField.text, let id = Int(text) else {
            ToastHelper.showToast(message: "Failed to get int ID from - \(mapIDTextField.text ?? "nil")", onView: view)
            return nil
        }
        return id
    }

    private func loadMap() {
        guard let request = onlineSwitch.isOn ? getRemoteMapDataRequest() : getLocalMapDataRequest() else {
            ToastHelper.showToast(message: "Failed to create map data request", onView: view)
            return
        }

        request
            .sink(receiveCompletion: { [self] in
                if case let .failure(error) = $0 {
                    ToastHelper.showToast(message: "Failed to load map with error - \(error)", onView: view)
                }
            }, receiveValue: { [self] mapData in
                showMap(mapData)
            })
            .store(in: &cancellables)
    }

    private func getRemoteMapDataRequest() -> AnyPublisher<MapData, Error>? {
        guard let id = getMapID() else {
            return nil
        }

        return WemapMap.shared.getMapData(mapID: id, token: Constants.token)
    }

    private func showMap(_ mapData: MapData) {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())
        
        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "samplesTVC") as! SamplesTableViewController
        vc.mapData = mapData
        vc.locationSourceType = LocationSourceType(rawValue: sourcePicker.selectedRow(inComponent: 0))
        
        show(vc, sender: nil)
    }

    // MARK: - Packdata Methods

    private func getLocalMapDataRequest() -> AnyPublisher<MapData, Error>? {
        guard let packdata else {
            return nil
        }

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let packdataURL = documentsURL.appendingPathComponent(packdata.fileName)

        return packdataManager.loadMapData(fromZip: packdataURL)
    }

    private func downloadNewPackdata() {
        guard let id = getMapID() else {
            return
        }

        checkAndDownloadButton.isEnabled = false

        packdataManager
            .downloadPackdata(mapID: id)
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    let message = "Failed to download packdata with error: \(error)"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: 5)
                    checkAndDownloadButton.isEnabled = true
                }
            }, receiveValue: { [unowned self] packdata in

                guard storePackdata(packdata) else {
                    return
                }
                checkAndDownloadButton.isSelected = false
                checkAndDownloadButton.setTitle("Downloaded (v\(packdata.version))", for: .normal)
                loadMapButton.isEnabled = true
            })
            .store(in: &cancellables)
    }

    private func checkForUpdates() {
        guard let id = getMapID() else {
            return
        }

        guard let etag = getETag() else {
            return
        }

        checkAndDownloadButton.isEnabled = false

        packdataManager
            .isNewPackdataAvailable(mapID: id, eTag: etag)
            .sink(receiveCompletion: { [unowned self] in
                checkAndDownloadButton.isEnabled = true
                if case let .failure(error) = $0 {
                    let message = "Failed to check for packdata updates with error: \(error)"
                    ToastHelper.showToast(message: message, onView: view)
                }
            }, receiveValue: { [unowned self] available in
                checkAndDownloadButton.isSelected = available
                let title = available ? "Download new packdata" : "Check for updates"
                checkAndDownloadButton.setTitle(title, for: .normal)
                if !available {
                    showAlert(message: "No new packdata available yet")
                }
            })
            .store(in: &cancellables)
    }

    private func loadPackdataIfAvailable() -> Packdata? {
        guard let data = userDefaults.data(forKey: "packdata") else {
            return nil
        }

        guard let packdata = try? JSONDecoder().decode(Packdata.self, from: data) else {
            ToastHelper.showToast(message: "Failed to decode packdata from user defaults", onView: view)
            return nil
        }
        return packdata
    }

    private func storePackdata(_ packdata: Packdata) -> Bool {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(packdata.fileName)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: packdata.fileURL, to: destinationURL)
        } catch {
            let message = "Failed to save downloaded packdata with error: \(error)"
            ToastHelper.showToast(message: message, onView: view, hideDelay: 5)
            return false
        }

        let encoded: Data
        do {
            encoded = try JSONEncoder().encode(packdata)
        } catch {
            let message = "Failed to encode packdata with error: \(error)"
            ToastHelper.showToast(message: message, onView: view, hideDelay: 5)
            return false
        }

        userDefaults.set(encoded, forKey: "packdata")
        self.packdata = packdata
        return true
    }

    private func getETag() -> String? {
        guard let etag = packdata?.eTag else {
            ToastHelper.showToast(message: "Failed to get ETag from user defaults", onView: view)
            return nil
        }
        return etag
    }
}

extension InitialViewController: UIPickerViewDataSource {

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        locationSourceTitles.count
    }
}

extension InitialViewController: UIPickerViewDelegate {

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        locationSourceTitles[row]
    }
}
