//
//  CreditsViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 07/05/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import UIKit
import WemapMapSDK

final class CreditsViewController: UIViewController {

    private static let cardRadius: CGFloat = 14
    private static let cardFont: UIFont = .preferredFont(forTextStyle: .callout)

    // MARK: - Title card elements

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Informations sur la carte de la gare"
        label.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var creditsLabel: UILabel = {
        let label = UILabel()
        let version = Bundle.map.version
        let credits = "Cette carte a été créée par notre partenaire Wemap grâce aux données d'Open StreetMap."
        label.text = "\(credits) Version actuelle : \(version)."
        label.font = Self.cardFont
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityTraits = .staticText
        return label
    }()

    private lazy var wemapButton = makeActionButton(
        title: "En savoir plus sur Wemap",
        accessibilityHint: "Ouverture dans une nouvelle fenêtre",
        action: #selector(wemapTapped)
    )

    private lazy var osmButton = makeActionButton(
        title: "Plus d'informations sur Open StreetMap",
        accessibilityHint: "Ouverture dans une nouvelle fenêtre",
        action: #selector(osmTapped)
    )

    // MARK: - Close button

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Fermer", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: 18, left: 24, bottom: 18, right: 24)
        button.accessibilityLabel = "Fermer"
        button.accessibilityTraits = .button
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Card

    private lazy var card = makeCard(arrangedSubviews: [
        makePadded(titleLabel),
        makeDivider(),
        makePadded(creditsLabel),
        makeDivider(),
        wemapButton,
        makeDivider(),
        osmButton,
        makeDivider(),
        closeButton
    ])

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupSheetPresentation()
        setupLayout()
        view.accessibilityElements = [titleLabel, closeButton, creditsLabel, wemapButton, osmButton]
    }

    // MARK: - Private

    private func setupSheetPresentation() {
        guard #available(iOS 15.0, *), let sheet = sheetPresentationController else { return }
        if #available(iOS 16.0, *) {
            sheet.detents = [.custom { [weak self] context in
                self?.preferredSheetHeight(within: context.maximumDetentValue)
            }, .large()]
        } else {
            sheet.detents = [.medium(), .large()]
        }
        sheet.prefersGrabberVisible = true
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
    }

    private func setupLayout() {
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }

    private func makeCard(arrangedSubviews: [UIView]) -> UIView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = Self.cardRadius
        card.clipsToBounds = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    /// Sized to the card rather than to a constant, so that the sheet neither clips its content nor leaves a
    /// gap under it when the text grows with Dynamic Type. Returning nil lets the detent fall back to medium.
    private func preferredSheetHeight(within maximum: CGFloat) -> CGFloat? {
        guard view.bounds.width > 0 else {
            return nil
        }
        let target = CGSize(width: view.bounds.width - 16, height: UIView.layoutFittingCompressedSize.height)
        let height = card.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return min(height.height + 32, maximum)
    }

    private func makePadded(_ view: UIView) -> UIView {
        let container = UIStackView(arrangedSubviews: [view])
        container.isLayoutMarginsRelativeArrangement = true
        container.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return container
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        return divider
    }

    private func makeActionButton(title: String, accessibilityHint: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Self.cardFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.contentHorizontalAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 18, left: 24, bottom: 18, right: 24)
        button.accessibilityLabel = title
        button.accessibilityHint = accessibilityHint
        button.accessibilityTraits = .link
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func wemapTapped() {
        UIApplication.shared.open(URL(string: "https://getwemap.com")!)
    }

    @objc private func osmTapped() {
        UIApplication.shared.open(URL(string: "https://www.openstreetmap.org/copyright")!)
    }
}
