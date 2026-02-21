/*
Copyright 2025 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import Foundation

/// Room retention policy (MSC1763 / m.room.retention).
struct RoomRetentionPolicy: Codable, Equatable {
    let maxLifetimeSeconds: Int

    var maxLifetimeMilliseconds: Int64 {
        Int64(maxLifetimeSeconds) * 1000
    }
}

/// UI option for disappearing messages.
enum DisappearingMessagesOption: Int, CaseIterable, Comparable, Codable {
    case off = 0
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30

    static func < (lhs: DisappearingMessagesOption, rhs: DisappearingMessagesOption) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var policy: RoomRetentionPolicy? {
        switch self {
        case .off:
            return nil
        case .oneDay:
            return RoomRetentionPolicy(maxLifetimeSeconds: 24 * 60 * 60)
        case .sevenDays:
            return RoomRetentionPolicy(maxLifetimeSeconds: 7 * 24 * 60 * 60)
        case .thirtyDays:
            return RoomRetentionPolicy(maxLifetimeSeconds: 30 * 24 * 60 * 60)
        }
    }

    init(policy: RoomRetentionPolicy?) {
        guard let policy else {
            self = .off
            return
        }
        switch policy.maxLifetimeSeconds {
        case 24 * 60 * 60:
            self = .oneDay
        case 7 * 24 * 60 * 60:
            self = .sevenDays
        case 30 * 24 * 60 * 60:
            self = .thirtyDays
        default:
            self = .off
        }
    }
}
