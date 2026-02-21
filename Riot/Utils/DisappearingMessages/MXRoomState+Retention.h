/*
Copyright 2025 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import <MatrixSDK/MatrixSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXRoomState (Retention)

/// Max lifetime in seconds from m.room.retention (MSC1763), or nil if not set.
- (nullable NSNumber *)vc_maxLifetimeSeconds;

@end

NS_ASSUME_NONNULL_END
