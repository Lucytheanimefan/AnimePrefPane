//
//  MALDelegate.m
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "MALDelegate.h"

#import "AnimeRequester.h"
#import "Constants.h"
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
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldScan:) name:MALAgentCenter object:nil];
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
    
    if (!_shouldScan)
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    }
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
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"title ==[c] %@ ", title];
        NSDictionary *matchingEntry = [currentEntries filteredArrayUsingPredicate:filter][0];
        
        if (matchingEntry)
        {
            os_log(OS_LOG_DEFAULT, "%@: New entry: %{public}s, matching entry: %{public}s", [self class], [title UTF8String], [matchingEntry[@"title"] UTF8String]);
            
            NSString *notificationInfoText = @"";
            
            // Check if the episode airing status has changed
            
            if (newEntry[@"airing_status"] != matchingEntry[@"airing_status"])
            {
                os_log(OS_LOG_DEFAULT, "%@: Differing airing status for %{public}s: %@ vs %@", [self class], [title UTF8String], newEntry[@"airing_status"], matchingEntry[@"airing_status"]);
                
                notificationInfoText = [NSString stringWithFormat:@"Airing status has changed to %@.", airingStatus[newEntry[@"airing_status"]]];
            }
            
            // Check if the user status has changed
            if (newEntry[@"user_status"] != matchingEntry[@"user_status"])
            {
                os_log(OS_LOG_DEFAULT, "%@: Differing user status for %{public}s: %@ vs %@", [self class], [title UTF8String], newEntry[@"user_status"], matchingEntry[@"user_status"]);
                
                notificationInfoText = [NSString stringWithFormat:@"%@ User watch status has changed to %@", notificationInfoText, userStatus[newEntry[@"user_status"]]];
            }
            
            if (notificationInfoText.length > 0)
            {

                NSString *notificationTitle = [NSString stringWithFormat:@"Status for %@ has changed", title];
                NSUserNotification *notif = [[NSUserNotification alloc]init];
                notif.title = notificationTitle;
                notif.informativeText = notificationInfoText;
                notif.otherButtonTitle = @"Dismiss";
                notif.actionButtonTitle = @"View";
                [self _deliverAnimeNotification:notif fromEntry:newEntry];
            }
        }
        else
        {
            NSUserNotification *notif = [[NSUserNotification alloc]init];
            notif.title = @"New anime added";
            notif.informativeText = [NSString stringWithFormat:@"%@ added to list", newEntry[@"title"]];
            
            [self _deliverAnimeNotification:notif fromEntry:newEntry];

        }
    }
    
    // Update the user defaults
    //#ifndef DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:newEntries forKey:@"malEntries"];
    //#endif
}

- (void) _deliverAnimeNotification: (NSUserNotification *)notif fromEntry:(NSDictionary *)newEntry
{
    NSImage *iconImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:newEntry[@"image_url"]]];
    notif.contentImage = iconImage;
    notif.userInfo = @{@"action_url":newEntry[@"url"]};
    os_log(OS_LOG_DEFAULT, "%@: Prepare to display notification: %{public}s", [self class], [notif.description UTF8String]);
    
    // Sanity check
    if (_shouldScan)
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
    }
}

@end
