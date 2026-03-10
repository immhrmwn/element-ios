// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

class CallCellContentView: UIView {
    
    private enum Constants {
        static let callSummaryWithBottomViewHeight: CGFloat = 20
        static let callSummaryStandaloneViewHeight: CGFloat = 20 + 44
        static let callSummaryCompactNoCTAHeight: CGFloat = 20 + 8 + 8   // compact, no CTA (ended call)
        static let callSummaryCompactWithCTAHeight: CGFloat = 20 + 12 + 12  // compact with inline CTA
        static let inlineCallBackButtonSize: CGFloat = 36
    }
    
    @IBOutlet private weak var paginationTitleView: UIView!
    @IBOutlet private weak var paginationLabel: UILabel!
    @IBOutlet private weak var paginationSeparatorView: UIView!
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet weak var avatarImageView: MXKImageView!
    @IBOutlet weak var callerNameLabel: UILabel!
    @IBOutlet weak var callIconView: UIImageView!
    @IBOutlet private weak var callStatusLabel: UILabel!
    @IBOutlet private weak var callSummaryHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bubbleInfoContainer: UIView!
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    @IBOutlet weak var bubbleInfoContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var readReceiptsContainerView: UIView!
    @IBOutlet weak var readReceiptsContentView: UIView!
    
    @IBOutlet weak var bottomContainerView: UIView!
    
    /// Inter-item spacing in the main content stack view
    let interItemSpacing: CGFloat = 8
    
    /// When true, hide avatar and room/caller name for a compact call history layout.
    var isCompactForCallHistory: Bool = false {
        didSet {
            applyCompactLayout()
        }
    }
    
    /// When true, show an inline icon-only call-back button next to the status text (compact layout).
    var showInlineCallBackButton: Bool = false {
        didSet {
            updateInlineCallBackButton()
        }
    }
    
    /// Icon for the inline call-back button (e.g. video or voice).
    var inlineCallBackIcon: UIImage? {
        didSet {
            inlineCallBackButton.setImage(inlineCallBackIcon, for: .normal)
        }
    }
    
    /// Called when the inline call-back button is tapped.
    var onInlineCallBackTapped: (() -> Void)?
    
    /// Accessibility label for the inline call-back button.
    var inlineCallBackAccessibilityLabel: String? {
        didSet {
            inlineCallBackButton.accessibilityLabel = inlineCallBackAccessibilityLabel
        }
    }
    
    private lazy var inlineCallBackButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(inlineCallBackButtonTapped), for: .touchUpInside)
        button.backgroundColor = .clear
        button.layer.cornerRadius = Constants.inlineCallBackButtonSize / 2
        button.layer.borderWidth = 1.5
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Constants.inlineCallBackButtonSize),
            button.heightAnchor.constraint(equalToConstant: Constants.inlineCallBackButtonSize)
        ])
        return button
    }()
    
    private var inlineCallBackSpacerView: UIView?
    
    @objc private func inlineCallBackButtonTapped() {
        onInlineCallBackTapped?()
    }
    
    var statusText: String? {
        didSet {
            callStatusLabel.text = statusText
        }
    }
    
    private(set) var theme: Theme = ThemeService.shared().theme
    
    private var showReadReceipts: Bool {
        get {
            return !self.readReceiptsContainerView.isHidden
        } set {
            self.readReceiptsContainerView.isHidden = !newValue
        }
    }
    
    func relayoutCallSummary() {
        let hasBottomView = !bottomContainerView.subviews.isEmpty
        let hasInlineButton = showInlineCallBackButton
        if hasBottomView {
            callSummaryHeightConstraint.constant = Constants.callSummaryWithBottomViewHeight
        } else if hasInlineButton {
            callSummaryHeightConstraint.constant = Constants.callSummaryCompactWithCTAHeight
        } else {
            callSummaryHeightConstraint.constant = isCompactForCallHistory
                ? Constants.callSummaryCompactNoCTAHeight
                : Constants.callSummaryStandaloneViewHeight
        }
    }
    
    private func updateInlineCallBackButton() {
        applyCompactLayout()
        guard let statusStack = callStatusLabel.superview as? UIStackView else { return }
        if showInlineCallBackButton {
            if inlineCallBackSpacerView == nil {
                let spacer = UIView()
                spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                inlineCallBackSpacerView = spacer
                statusStack.addArrangedSubview(spacer)
                statusStack.addArrangedSubview(inlineCallBackButton)
            }
        } else {
            if let spacer = inlineCallBackSpacerView {
                statusStack.removeArrangedSubview(spacer)
                spacer.removeFromSuperview()
                inlineCallBackSpacerView = nil
            }
            if inlineCallBackButton.superview != nil {
                statusStack.removeArrangedSubview(inlineCallBackButton)
                inlineCallBackButton.removeFromSuperview()
            }
        }
        relayoutCallSummary()
    }
    
    private func applyCompactLayout() {
        avatarImageView.isHidden = isCompactForCallHistory
        callerNameLabel.isHidden = isCompactForCallHistory
        bubbleInfoContainer.isHidden = isCompactForCallHistory
        
        if let stackView = bgView?.subviews.first as? UIStackView {
            stackView.arrangedSubviews.first?.isHidden = isCompactForCallHistory
            stackView.spacing = isCompactForCallHistory ? (showInlineCallBackButton ? 8 : 4) : 8
        }
        
        relayoutCallSummary()
    }
    
    func render(_ cellData: MXKCellData) {
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        if bubbleCellData.isPaginationFirstBubble {
            paginationTitleView.isHidden = false
            paginationLabel.text = bubbleCellData.eventFormatter.dateString(from: bubbleCellData.date, withTime: false)?.uppercased()
        } else {
            paginationTitleView.isHidden = true
        }
        
        avatarImageView.enableInMemoryCache = true
    }

}

extension CallCellContentView: NibLoadable {
    
}

extension CallCellContentView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        paginationLabel.textColor = theme.tintColor
        paginationSeparatorView.backgroundColor = theme.tintColor
        
        bgView.backgroundColor = theme.colors.tile
        callerNameLabel.textColor = theme.textPrimaryColor
        callIconView.tintColor = theme.textSecondaryColor
        callStatusLabel.textColor = theme.textSecondaryColor
        inlineCallBackButton.tintColor = theme.tintColor
        inlineCallBackButton.layer.borderColor = theme.tintColor.cgColor
        
        if let bottomContainerView = bottomContainerView as? Themable {
            bottomContainerView.update(theme: theme)
        }
    }
    
}

// MARK: - RoomCellReadReceiptsDisplayable

extension CallCellContentView: RoomCellReadReceiptsDisplayable {
    
    func addReadReceiptsView(_ readReceiptsView: UIView) {
        self.readReceiptsContentView.vc_removeAllSubviews()
        self.readReceiptsContentView.vc_addSubViewMatchingParent(readReceiptsView)
        self.showReadReceipts = true
    }
    
    func removeReadReceiptsView() {
        self.showReadReceipts = false
        self.readReceiptsContentView.vc_removeAllSubviews()
    }
}
