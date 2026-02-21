/*
Copyright 2025 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation
import MatrixSDK

extension MXRoomState {
    /// Max lifetime in seconds from m.room.retention (MSC1763), or nil if not set.
    func vc_retentionMaxLifetimeSeconds() -> Int? {
        vc_maxLifetimeSeconds()?.intValue
    }
}
