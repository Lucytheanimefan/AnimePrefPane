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
    if (self) {
        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = [MALNotificationCenterDelegate sharedDelegate];
        airingStatus = @{@1:@"Airing", @2:@"Aired", @3:@"Not aired"};
        userStatus = @{@1:@"Watching", @2:@"Completed", @3:@"On hold", @4:@"Dropped", @5:@"Plan to watch"};
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

- (void)startScanningForNotifications
{
    NSArray <NSDictionary *> *currentEntries = [[NSUserDefaults standardUserDefaults] objectForKey:@"malEntries"];
    NSString *malUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"malUsername"];
    
    // Get the new entries
    __block NSArray <NSDictionary *> *newEntries;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[AnimeRequester sharedInstance] makeGETRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] withCompletion:^(NSDictionary * json) {
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
                notif.title = notificationTitle;
                notif.informativeText = notificationInfoText;
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
            }

        }
        else
        {
            // The new anime has been recently added to MAL, update the user defaults
            [[NSUserDefaults standardUserDefaults] setObject:newEntries forKey:@"malEntries"];
        }
    }
}

@end
