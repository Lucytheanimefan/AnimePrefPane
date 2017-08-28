//
//  MALNotificationCenterDelegate.m
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "MALNotificationCenterDelegate.h"


#import <AppKit/AppKit.h>

@implementation MALNotificationCenterDelegate

+ (id) sharedDelegate
{
    static MALNotificationCenterDelegate *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSURL *actionURL = [NSURL URLWithString: notification.userInfo[@"action_url"]];
    [[NSWorkspace sharedWorkspace] openURL:actionURL];
}

@end
