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
        let source: String
        if policySeconds != nil {
            source = "RiotSettings"
        } else {
            let room = mainSession?.room(withRoomId: roomId)
            policySeconds = room?.dangerousSyncState?.vc_maxLifetimeSeconds()
            source = "roomState"
        }
        MXLog.debug("[RoomVC] bannerDurationText roomId=\(roomId) policySeconds=\(policySeconds?.stringValue ?? "nil") source=\(source)")
        guard let seconds = policySeconds?.intValue, seconds > 0 else { return nil }
        
        // TEST: 60 sec (1 min) displays as "1 day"
        if seconds == 60 { return VectorL10n.roomDetailsDisappearingMessages1Day }
        
        let days = seconds / (24 * 60 * 60)
        switch days {
        case 1: return VectorL10n.roomDetailsDisappearingMessages1Day
        case 7: return VectorL10n.roomDetailsDisappearingMessages7Days
        case 30: return VectorL10n.roomDetailsDisappearingMessages30Days
        default: return VectorL10n.roomDisappearingMessagesDurationDays(days)
        }
    }
}
