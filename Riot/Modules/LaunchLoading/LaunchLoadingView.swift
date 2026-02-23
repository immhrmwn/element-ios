/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import UIKit
import Reusable

@objcMembers
final class LaunchLoadingView: UIView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var progressContainer: UIStackView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
    
    // MARK: - Setup
    
    static func instantiate(startupProgress: MXSessionStartupProgress?) -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        startupProgress?.delegate = view
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        progressContainer.isHidden = true
        startFloatAnimation()
    }
    
    private func startFloatAnimation() {
        UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat]) { [weak self] in
            self?.logoImageView?.transform = CGAffineTransform(translationX: 0, y: -8)
        }
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
    }
}

extension LaunchLoadingView: MXSessionStartupProgressDelegate {
    func sessionDidUpdateStartupProgress(state: MXSessionStartupProgress.State) {
        update(with: state)
        
    }
    
    private func update(with state: MXSessionStartupProgress.State) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.update(with: state)
            }
            return
        }
        
        // Sync may be doing a lot of heavy work on the main thread and the status text
        // does not update reliably enough without explicitly refreshing
        CATransaction.begin()
        progressContainer.isHidden = false
        progressView.progress = Float(state.progress)
        statusLabel.text = state.showDelayWarning ? VectorL10n.launchLoadingDelayWarning : VectorL10n.launchLoadingGeneric
        CATransaction.commit()
    }
}
