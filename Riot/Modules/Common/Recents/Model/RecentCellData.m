/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentCellData.h"

#import "MXRoom+Riot.h"
#import "MXRoomState+Retention.h"

#import "GeneratedInterface-Swift.h"

@implementation RecentCellData

- (BOOL)isLastMessageExpiredByRetention
{
    if (self.isSuggestedRoom || !self.roomSummary.lastMessage) { return NO; }
    
    NSNumber *policySeconds = [RiotSettings.shared roomRetentionMaxLifetimeSecondsForRoomId:self.roomSummary.roomId];
    if (policySeconds == nil)
    {
        MXRoom *room = [self.mxSession roomWithRoomId:self.roomSummary.roomId];
        policySeconds = [room.dangerousSyncState vc_maxLifetimeSeconds];
    }
    if (policySeconds == nil || policySeconds.integerValue <= 0) { return NO; }
    
    NSNumber *retentionStart = [RiotSettings.shared roomRetentionStartTimestampForRoomId:self.roomSummary.roomId];
    NSTimeInterval startTs = retentionStart != nil ? retentionStart.doubleValue : 0;
    NSTimeInterval cutoff = [[NSDate date] timeIntervalSince1970] - policySeconds.doubleValue;
    uint64_t ts = self.roomSummary.lastMessage.originServerTs;
    
    return (ts >= (uint64_t)startTs && ts < (uint64_t)cutoff);
}

//  Adds K handling to super implementation
- (NSString*)notificationCountStringValue
{
    NSString *stringValue;
    NSUInteger notificationCount = self.notificationCount;
    
    if (notificationCount > 1000)
    {
        CGFloat value = notificationCount / 1000.0;
        stringValue = [VectorL10n largeBadgeValueKFormat:value];
    }
    else
    {
        stringValue = [NSString stringWithFormat:@"%tu", notificationCount];
    }
    
    return stringValue;
}

//  Adds mentions-only handling to super implementation
- (NSUInteger)notificationCount
{
    MXRoom *room = [self.mxSession roomWithRoomId:self.roomSummary.roomId];
    // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
    if (room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        return super.highlightCount;
    }
    
    return super.notificationCount;
}

//  Adds "Empty Room" case to super implementation
- (NSString *)roomDisplayname
{
    NSString *result = [super roomDisplayname];
    if (!result.length)
    {
        result = [VectorL10n roomDisplaynameEmptyRoom];
    }
    return result;
}

// Hide last message when expired by room retention (disappearing messages)
- (NSString *)lastEventTextMessage
{
    if ([self isLastMessageExpiredByRetention])
    {
        return @"";
    }
    return [super lastEventTextMessage];
}

- (NSAttributedString *)lastEventAttributedTextMessage
{
    if ([self isLastMessageExpiredByRetention])
    {
        return nil;
    }
    return [super lastEventAttributedTextMessage];
}

@end
