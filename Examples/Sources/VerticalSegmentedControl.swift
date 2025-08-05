//
//  VerticalSegmentedControl.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 20/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import UIKit

protocol VerticalSegmentedControlDelegate: AnyObject {
    func verticalSegmentedControl(_ control: VerticalSegmentedControl, didSelectSegmentAt index: Int)
}

open class VerticalSegmentedControl: UIView {
    
    // MARK: - Public Properties
    
    var segmentTitles: [String] = [] {
        didSet {
            reloadSegments()
        }
    }
    
    var selectedIndex: Int = 0 {
        didSet {
            updateSelection()
            delegate?.verticalSegmentedControl(self, didSelectSegmentAt: selectedIndex)
        }
    }
    
    var buttonHeight: CGFloat = 40
    var spacing: CGFloat = 8
    
    var selectedBackgroundColor: UIColor = .systemBlue
    var deselectedBackgroundColor: UIColor = .lightGray
    var titleColor: UIColor = .white
    var font: UIFont = .systemFont(ofSize: 17, weight: .medium)
    
    var cornerRadius: CGFloat = 12
    
    /// Called whenever a new segment is selected
    weak var delegate: VerticalSegmentedControlDelegate?
    
    // MARK: - Private Properties
    
    private var buttons: [UIButton] = []
    private let stackView = UIStackView()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }
    
    // MARK: - Public Methods
    
    func selectSegment(at index: Int) {
        guard index >= 0, index < buttons.count else { return }
        selectedIndex = index
    }
    
    // MARK: - Private Methods
    
    private func setupStackView() {
        translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = spacing
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func reloadSegments() {
        // Remove old buttons
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, title) in segmentTitles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = font
            button.setTitleColor(titleColor, for: .normal)
            button.backgroundColor = deselectedBackgroundColor
            button.layer.cornerRadius = cornerRadius
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            button.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
            
            stackView.insertArrangedSubview(button, at: 0)
            buttons.append(button)
        }
        
        updateSelection()
    }
    
    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            button.backgroundColor = (index == selectedIndex)
                ? selectedBackgroundColor
                : deselectedBackgroundColor
        }
    }
    
    @objc private func segmentTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
    }
    
    override open var intrinsicContentSize: CGSize {
        // Determine the total height based on number of buttons, height, and spacing
        let buttonCount = buttons.count
        let totalHeight = CGFloat(buttonCount) * buttonHeight + CGFloat(max(buttonCount - 1, 0)) * spacing
        // Estimate width from max button title
        let maxWidth: CGFloat = buttons
            .map(\.intrinsicContentSize.width)
            .max() ?? 40
        let padding: CGFloat = 8 // Add some internal padding
        return CGSize(width: maxWidth + padding, height: totalHeight)
    }
}
