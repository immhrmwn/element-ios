//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

/// Banner displayed in room when disappearing messages (retention) is enabled.
@objcMembers
final class DisappearingMessagesBannerView: UIView, Themable {
    
    // MARK: - Properties
    
    private let stackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 10
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(systemName: "clock") {
            v.image = img.withRenderingMode(.alwaysTemplate)
        }
        return v
    }()
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private var theme: Theme!
    
    // MARK: - Setup
    
    static func instantiate(durationText: String) -> DisappearingMessagesBannerView {
        let view = DisappearingMessagesBannerView()
        view.titleLabel.text = VectorL10n.roomDisappearingMessagesBanner(durationText)
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(stackView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Public
    
    func updateText(_ text: String) {
        titleLabel.text = text
    }
    
    func update(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.tile
        iconImageView.tintColor = theme.colors.primaryContent
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.footnote
    }
}
