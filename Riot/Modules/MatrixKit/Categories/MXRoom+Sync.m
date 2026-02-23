/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXRoom+Sync.h"
#import "MXLog.h"

@implementation MXRoom (Sync)

- (MXRoomState *)dangerousSyncState
{
    __block MXRoomState *syncState;

    // If syncState is called from the right place, the following call will be
    // synchronous and every thing will be fine
    [self state:^(MXRoomState *roomState) {
        syncState = roomState;
    }];

    if (!syncState)
    {
        MXLogWarning(@"[MXRoom+Sync] syncState failed. Room state may not be loaded yet (e.g. invited room or room in transition).");
    }

    return syncState;
}

@end
