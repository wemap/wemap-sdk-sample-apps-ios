//
//  InitialViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import RxCocoa
import RxSwift
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
    
    private let disposeBag = DisposeBag()

    // MARK: - Packdata Properties

    private lazy var packdataManager: PackdataManaging = DependencyManager.getPackdataManager()
    private let fileManager: FileManager = .default
    private let userDefaults: UserDefaults = .standard
    private var packdata: Packdata?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onlineSwitch
            .rx.isOn
            .subscribe(onNext: { [unowned self] in
                onlineLabel.text = $0 ? "Online" : "Offline"
                packdataStackView.isHidden = $0
                loadMapButton.isEnabled = $0 || packdata != nil
            }).disposed(by: disposeBag)
        
        // uncomment if you want to use dev environment
//        WemapCore.setEnvironment(.dev)
//        WemapCore.setItinerariesEnvironment(.dev)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapIDTextField.text = "\(Constants.mapID)"

        let locationSourceTitles = LocationSourceType.allCases.map(\.name)
        
        Driver
            .of(locationSourceTitles)
            .drive(sourcePicker.rx.itemTitles) { _, element in element }
            .disposed(by: disposeBag)
        
        // if you need to retrieve all points of interest for some map in advance
//        ServiceFactory
//            .getPointOfInterestService()
//            .pointsOfInterestList(mapID: Constants.mapID)
//            .subscribe(onSuccess: {
//                debugPrint("received pois - \($0)")
//            }, onFailure: {
//                debugPrint("failed to receive pois with error - \($0)")
//            })
//            .disposed(by: disposeBag)

        packdata = loadPackdataIfAvailable()
        if let packdata {
            packdataLabel.text = "Offline packdata (v\(packdata.version))"
            loadMapButton.isEnabled = true
        } else {
            checkAndDownloadButton.setTitle("Download", for: .selected)
            checkAndDownloadButton.isSelected = true
        }
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
            .subscribe(onSuccess: { [self] mapData in
                showMap(mapData)
            }, onFailure: { [self] in
                ToastHelper.showToast(message: "Failed to load map with error - \($0)", onView: view)
            })
            .disposed(by: disposeBag)
    }

    private func getRemoteMapDataRequest() -> Single<MapData>? {
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

    private func getLocalMapDataRequest() -> Single<MapData>? {
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
            .subscribe(onSuccess: { [unowned self] packdata in

                guard storePackdata(packdata) else {
                    return
                }
                checkAndDownloadButton.isSelected = false
                checkAndDownloadButton.setTitle("Downloaded (v\(packdata.version))", for: .normal)
                loadMapButton.isEnabled = true

            }, onFailure: { [unowned self] in
                ToastHelper.showToast(message: "Failed to download packdata with error: \($0)", onView: view, hideDelay: 5)
                checkAndDownloadButton.isEnabled = true
            })
            .disposed(by: disposeBag)
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
            .subscribe(onSuccess: { [unowned self] available in
                checkAndDownloadButton.isSelected = available
                let title = available ? "Download new packdata" : "Check for updates"
                checkAndDownloadButton.setTitle(title, for: .normal)
                if !available {
                    showAlert(message: "No new packdata available yet")
                }
            }, onFailure: { [unowned self] in
                ToastHelper.showToast(message: "Failed to check for packdata updates with error: \($0)", onView: view)
            }, onDisposed: { [unowned self] in
                checkAndDownloadButton.isEnabled = true
            })
            .disposed(by: disposeBag)
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
