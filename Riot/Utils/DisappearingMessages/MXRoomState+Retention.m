/*
Copyright 2025 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

#import "MXRoomState+Retention.h"
#import <MatrixSDK/MXEvent.h>

@implementation MXRoomState (Retention)

- (NSNumber *)vc_maxLifetimeSeconds
{
    NSArray<MXEvent *> *events = [self stateEventsWithType:kMXEventTypeStringRoomRetention];
    MXEvent *event = events.lastObject;
    if (!event.content[@"max_lifetime"]) {
        return nil;
    }
    NSNumber *maxLifetimeMs = event.content[@"max_lifetime"];
    if (![maxLifetimeMs isKindOfClass:NSNumber.class] || maxLifetimeMs.longLongValue <= 0) {
        return nil;
    }
    long long seconds = maxLifetimeMs.longLongValue / 1000;
    return @(seconds);
}

@end
