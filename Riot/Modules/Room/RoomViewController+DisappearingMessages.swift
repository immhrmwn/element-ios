//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixSDK

/// RoomViewController disappearing messages (retention) banner handling
@objc extension RoomViewController {
    
    func updateDisappearingMessagesBannerViewVisibility() {
        let durationText = disappearingMessagesBannerDurationText()
        let roomId = roomDataSource?.roomId ?? "?"
        MXLog.debug("[RoomVC] updateDisappearingMessagesBanner roomId=\(roomId) durationText=\(durationText ?? "nil")")
        if let durationText = durationText {
            showDisappearingMessagesBannerView(durationText: durationText)
        } else {
            hideDisappearingMessagesBannerView()
        }
    }
    
    func hideDisappearingMessagesBannerView() {
        disappearingMessagesBannerView?.removeFromSuperview()
        disappearingMessagesBannerView = nil
    }
    
    func showDisappearingMessagesBannerView(durationText: String) {
        // Always remove and recreate to avoid stale banner text (e.g. after changing retention in Room Settings)
        hideDisappearingMessagesBannerView()
        
        let bannerView = DisappearingMessagesBannerView.instantiate(durationText: durationText)
        topBannersStackView?.addArrangedSubview(bannerView)
        disappearingMessagesBannerView = bannerView
    }
    
    private func disappearingMessagesBannerDurationText() -> String? {
        guard let roomId = roomDataSource?.roomId else { return nil }
        var policySeconds: NSNumber? = RiotSettings.shared.roomRetentionMaxLifetimeSeconds(forRoomId: roomId)
        if policySeconds == nil || policySeconds?.intValue ?? 0 <= 0 {
            policySeconds = mainSession?.room(withRoomId: roomId)?.dangerousSyncState?.vc_maxLifetimeSeconds()
        }
        MXLog.debug("[RoomVC] bannerDurationText roomId=\(roomId) policySeconds=\(policySeconds?.stringValue ?? "nil")")
        guard let seconds = policySeconds?.intValue, seconds > 0 else { return nil }
        
        switch seconds {
        case 60: return VectorL10n.roomDetailsDisappearingMessages1Minute
        case 5 * 60: return VectorL10n.roomDetailsDisappearingMessages5Minutes
        case 60 * 60: return VectorL10n.roomDetailsDisappearingMessages1Hour
        case 24 * 60 * 60: return VectorL10n.roomDetailsDisappearingMessages1Day
        case 7 * 24 * 60 * 60: return VectorL10n.roomDetailsDisappearingMessages1Week
        case 30 * 24 * 60 * 60: return VectorL10n.roomDetailsDisappearingMessages1Month
        default:
            let days = seconds / (24 * 60 * 60)
            return VectorL10n.roomDisappearingMessagesDurationDays(days)
        }
    }
}
