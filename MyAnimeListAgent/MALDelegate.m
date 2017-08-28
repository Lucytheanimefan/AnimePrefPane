//
//  MALDelegate.m
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "MALDelegate.h"

#import "AnimeRequester.h"
#import "MALNotificationCenterDelegate.h"

#import <AppKit/AppKit.h>
#import <os/log.h>

@implementation MALDelegate
{
    NSDictionary *airingStatus;
    NSDictionary *userStatus;
}

+ (id) sharedDelegate
{
    static MALDelegate *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

-(id)init
{
    self = [super init];
    if (self)
    {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = [MALNotificationCenterDelegate sharedDelegate];
        airingStatus = @{@1:@"Airing", @2:@"Aired", @3:@"Not aired"};
        userStatus = @{@1:@"Watching", @2:@"Completed", @3:@"On hold", @4:@"Dropped", @5:@"Plan to watch"};
        _shouldScan = NO;
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldScan:) name:@"MyAnimeListAgent" object:nil];
    }
    return self;
}

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    os_log(OS_LOG_DEFAULT, "%@: Got a connection!", [self className]);
    NSXPCInterface *malInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MALProtocol)];
    newConnection.exportedInterface = malInterface;
    newConnection.exportedObject = self;
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MALProtocol)];
    [newConnection resume];
    return YES;
}

         
-(void)shouldScan:(NSNotification *)myNotification
{
    _shouldScan = [myNotification.userInfo[@"shouldScan"] boolValue];
    os_log(OS_LOG_DEFAULT, "%@: Should scan: %hhd", [self class], _shouldScan);
}
         
-(void)setShouldScan:(BOOL)shouldScan
{
    _shouldScan = shouldScan;
}

- (void)startScanningForNotifications
{
    if (!_shouldScan)
    {
        os_log(OS_LOG_DEFAULT, "%@: Don't proceed to scan", [self class]);
        return;
    }
    os_log(OS_LOG_DEFAULT, "%@: -----------Start scanning for notifications---------", [self class]);
    NSArray <NSDictionary *> *currentEntries = [[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"];
    NSString *malUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"malUsername"];
    if (!malUsername)
    {
        malUsername = @"Silent_Muse";
    }
    
    // Get the new entries
    __block NSArray <NSDictionary *> *newEntries;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] withCompletion:^(NSDictionary * json) {
        os_log(OS_LOG_DEFAULT, "%@: Anime requestor response: %@", [self class], json);
        newEntries = (NSArray <NSDictionary *> *)json;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    // Compare the new entries to the old entries
    for (NSDictionary *newEntry in newEntries)
    {
        // Search for the title in the old entries
        NSString *title = newEntry[@"title"];
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"title contains[c] %@ ", title];
        NSDictionary *matchingEntry = [currentEntries filteredArrayUsingPredicate:filter][0];
        
        os_log(OS_LOG_DEFAULT, "%@: New entry: %@, matching entry: %@", [self class], title, matchingEntry[@"title"]);

        if (matchingEntry)
        {
            NSString *notificationInfoText = @"";
            
            // Compare watched episode count/user watch status
            if (newEntry[@"airing_status"] != matchingEntry[@"airing_status"])
            {
                notificationInfoText = [NSString stringWithFormat:@"Airing status has changed to %@.", airingStatus[newEntry[@"airing_status"]]];
            }
            if (newEntry[@"user_status"] != matchingEntry[@"user_status"])
            {
                notificationInfoText = [NSString stringWithFormat:@"%@ User watch status has changed to %@", notificationInfoText, userStatus[newEntry[@"user_status"]]];
            }
            
            if (notificationInfoText.length > 0)
            {
                NSString *notificationTitle = [NSString stringWithFormat:@"Status for %@ has changed", title];
                NSUserNotification *notif = [[NSUserNotification alloc]init];
                NSImage *iconImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:newEntry[@"image_url"]]];
                notif.title = notificationTitle;
                notif.informativeText = notificationInfoText;
                notif.contentImage = iconImage;
                notif.otherButtonTitle = @"Dismiss";
                notif.actionButtonTitle = @"View";
                notif.userInfo = @{@"action_url":newEntry[@"url"]};
                os_log(OS_LOG_DEFAULT, "%@: Prepare to display notification: %@", [self class], notif.description);
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
            }
        }
        // Update the user defaults
#ifndef DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:newEntries forKey:@"malEntries"];
#endif
    }
}

@end
