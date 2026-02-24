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
/// Raw values are approximate ordering; actual duration is from maxLifetimeSeconds.
enum DisappearingMessagesOption: Int, CaseIterable, Comparable, Codable {
    case off = 0
    case oneMinute = 1
    case fiveMinutes = 2
    case oneHour = 3
    case oneDay = 4
    case oneWeek = 5
    case oneMonth = 6

    static func < (lhs: DisappearingMessagesOption, rhs: DisappearingMessagesOption) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Duration in seconds for this option (nil for off).
    var maxLifetimeSeconds: Int? {
        switch self {
        case .off: return nil
        case .oneMinute: return 60
        case .fiveMinutes: return 5 * 60
        case .oneHour: return 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        case .oneMonth: return 30 * 24 * 60 * 60
        }
    }

    var policy: RoomRetentionPolicy? {
        guard let sec = maxLifetimeSeconds else { return nil }
        return RoomRetentionPolicy(maxLifetimeSeconds: sec)
    }

    init(policy: RoomRetentionPolicy?) {
        guard let policy else {
            self = .off
            return
        }
        switch policy.maxLifetimeSeconds {
        case 60: self = .oneMinute
        case 5 * 60: self = .fiveMinutes
        case 60 * 60: self = .oneHour
        case 24 * 60 * 60: self = .oneDay
        case 7 * 24 * 60 * 60: self = .oneWeek
        case 30 * 24 * 60 * 60: self = .oneMonth
        default: self = .off
        }
    }
}
