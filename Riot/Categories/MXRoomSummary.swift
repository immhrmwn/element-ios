//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Notification.Name {
    static let roomSummaryDidRemoveExpiredDataFromStore = Notification.Name(MXRoomSummary.roomSummaryDidRemoveExpiredDataFromStore)
}

extension MXRoomSummary {
    @objc static let roomSummaryDidRemoveExpiredDataFromStore = "roomSummaryDidRemoveExpiredDataFromStore"
    @objc static let roomRetentionStateEventType = "m.room.retention"
    @objc static let roomRetentionEventMaxLifetimeKey = "max_lifetime"
    @objc static let roomRetentionMaxLifetime = "roomRetentionMaxLifetime"
    
    /// Get the room messages retention period in ms. Returns 0 when retention is Off (no removal).
    private func roomRetentionPeriodInMillis() -> UInt64 {
        if let raw = self.others[MXRoomSummary.roomRetentionMaxLifetime] as? NSNumber {
            let period = raw.uint64Value
            if period > 0 { return period }
            return 0  // max_lifetime=0 means Off
        }
        return Tools.durationInMs(fromDays: 365)  // not set: default cleanup
    }
    
    /// Get the timestamp below which the received messages must be removed from the store, and the display
    @objc func minimumTimestamp() -> UInt64 {
        let periodInMs = self.roomRetentionPeriodInMillis()
        let currentTs = (UInt64)(Date().timeIntervalSince1970 * 1000)
        return (currentTs - periodInMs)
    }
    
    /// Remove the expired messages from the store.
    /// If some data are removed, this operation posts the notification: roomSummaryDidRemoveExpiredDataFromStore.
    /// This operation does not commit the potential change. We let the caller trigger the commit when this is the more suitable.
    /// When retention is Off (max_lifetime=0), does nothing.
    /// When room has explicit retention (m.room.retention), skips store removal – RoomDataSource filters at display time
    /// so only messages sent after retention was enabled are hidden. Store removal would wrongly delete older messages.
    ///
    /// Provide a boolean telling whether some data have been removed.
    @objc func removeExpiredRoomContentsFromStore() -> Bool {
        let periodMs = roomRetentionPeriodInMillis()
        if periodMs == 0 { return false }  // Off = no removal
        // Room has explicit retention: don't remove from store. RoomDataSource filters display using retentionStartTimestamp.
        // Store removal would delete messages sent before retention was enabled (e.g. "satu" when only "dua" should disappear).
        if self.others[MXRoomSummary.roomRetentionMaxLifetime] != nil { return false }
        let cutoff = (UInt64)(Date().timeIntervalSince1970 * 1000) - periodMs
        let ret = self.mxSession.store.removeAllMessagesSent(before: cutoff, inRoom: roomId)
        if ret {
            NotificationCenter.default.post(name: .roomSummaryDidRemoveExpiredDataFromStore, object: self)
        }
        return ret
    }
}
