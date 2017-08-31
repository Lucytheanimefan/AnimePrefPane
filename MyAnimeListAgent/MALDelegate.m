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

@interface MALDelegate()

@property (nonatomic) NSString *currentNotificationSource;

@end

@implementation MALDelegate
{
    NSDictionary *airingStatus;
    NSDictionary *userStatus;
    NSString *username;
    NSString *password;
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
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldScan:) name:AnimeNotificationCenter object:nil];
        _currentNotificationSource = @"";
        
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
    os_log(OS_LOG_DEFAULT, "%@: UserInfo: %{public}s", [self class], [myNotification.userInfo.description UTF8String]);
    _shouldScan = [myNotification.userInfo[@"shouldScan"] boolValue];
    os_log(OS_LOG_DEFAULT, "%@: Should scan: %hhd", [self class], _shouldScan);
    _currentNotificationSource = myNotification.userInfo[@"source"];
    if ([_currentNotificationSource isEqualToString:FuniAgentCenter])
    {
        os_log(OS_LOG_DEFAULT, "%@: Set the username and password for funimation", [self class]);
        // Need the username and password!
        username = myNotification.userInfo[@"username"];
        password = myNotification.userInfo[@"password"];
    }
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
    [self _startScanningForNotifications:_currentNotificationSource];
}

- (void) _startScanningForNotifications:(NSString *) source;
{
    if ([source isEqualToString:MALAgentCenter])
    {
        [self _startScanningForMALNotifications];
    }
    else if ([source isEqualToString:FuniAgentCenter])
    {
        [self _startScanningForFuniNotifications];
    }
}

- (void)_startScanningForMALNotifications
{
    if (!_shouldScan)
    {
        os_log(OS_LOG_DEFAULT, "%@: Don't proceed to scan", [self class]);
        return;
    }
    os_log(OS_LOG_DEFAULT, "%@: -----------Start scanning for MAL notifications---------", [self class]);
    NSArray <NSDictionary *> *currentEntries = [[NSUserDefaults standardUserDefaults] objectForKey:malEntries];
    NSString *malUsername = [[NSUserDefaults standardUserDefaults] objectForKey:@"malUsername"];
    if (!malUsername)
    {
        malUsername = @"Silent_Muse";
    }
    
    // Get the new entries
    __block NSArray <NSDictionary *> *newEntries;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[AnimeRequester sharedInstance] makeRequest:@"myanimelist" withParameters:[NSString stringWithFormat:@"username=%@",malUsername] postParams:nil isPost:NO withCompletion:^(NSDictionary * json) {
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
            // TODO: fix, this is not working as expected
            // No matching entry, a new anime was added
            
            NSUserNotification *notif = [[NSUserNotification alloc]init];
            notif.title = @"New anime added";
            notif.informativeText = [NSString stringWithFormat:@"%@ added to list", newEntry[@"title"]];
            
            //[self _deliverAnimeNotification:notif fromEntry:newEntry];

        }
    }
    
    // Update the user defaults
    //#ifndef DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:newEntries forKey:@"malEntries"];
    //#endif
}

- (void) _startScanningForFuniNotifications
{
    if (!_shouldScan)
    {
#ifdef DEBUG
        os_log(OS_LOG_DEFAULT, "%@: Don't proceed to scan", [self class]);
#endif
        return;
    }
#ifdef DEBUG
    os_log(OS_LOG_DEFAULT, "%@: -----------Start scanning for Funimation notifications---------", [self class]);
#endif
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:funiQueue];
    NSDictionary *currentQueue = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#ifdef DEBUG
    os_log(OS_LOG_DEFAULT, "%@: Current funiQueue: %{public}s", [self class], [currentQueue.description UTF8String]);
#endif
    NSArray *currentEntries = currentQueue[@"items"];
    NSArray *newEntries;
    
    __block NSDictionary *newQueue;
    
    if (!username || !password)
    {
#ifdef DEBUG
        os_log_error(OS_LOG_DEFAULT, "%@: No available funimation username %{public}s or password %{public}s", [self class], [username UTF8String], [password UTF8String]);
#endif
        // TODO: display a modal sheet
        return;
    }
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [[AnimeRequester sharedInstance]makeRequest:@"funiLogin" withParameters:nil postParams:@{@"username":username, @"password":password} isPost:YES withCompletion:^(NSDictionary *json) {
        
        NSString *funiAuthToken = json[@"token"];
        // Get Funimation queue
        [[AnimeRequester sharedInstance] makeRequest:funiQueue withParameters:nil postParams:@{@"funiAuthToken":funiAuthToken} isPost:YES withCompletion:^(NSDictionary * json) {
#ifdef DEBUG
            os_log(OS_LOG_DEFAULT, "%@: Funimation results: %{public}s", [self class], [[json description]UTF8String]);
#endif
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:json];
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:funiQueue];
            
            newQueue = json;
            
            dispatch_semaphore_signal(sema);
        }];
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
#ifdef DEBUG
    os_log(OS_LOG_DEFAULT, "%@: New funimation queue: %{public}s", [self class], newQueue.description.UTF8String);
#endif
    
    newEntries = newQueue[@"items"];
    
    // Compare the new and old funimation queue entries
    for (NSDictionary *showEntry in newEntries)
    {
        NSString *title = showEntry[@"show"][@"title"];
#ifdef DEBUG
        os_log(OS_LOG_DEFAULT, "%@: Currently examining funi title: %{public}s", [self class], title.UTF8String);
#endif
        NSPredicate *filter;
        NSDictionary *matchingEntry;
        if (currentEntries.count > 0)
        {
            filter = [NSPredicate predicateWithFormat:@"show.title ==[c] %@ ", title];
            matchingEntry = [currentEntries filteredArrayUsingPredicate:filter][0];
        }
        NSUserNotification *notification;
        if (matchingEntry)
        {
            os_log(OS_LOG_DEFAULT, "%@: Matching funimation entry from cached: %{public}s", [self class], matchingEntry.description.UTF8String);
            
            // Check if all of the other values are the same
            if (![matchingEntry isEqualToDictionary:showEntry])
            {
                notification = [[NSUserNotification alloc] init];
                notification.title = Funimation;
                notification.informativeText = [NSString stringWithFormat:@"Status of %@ changed on Funimation", title];
            }
        }
        else
        {
            os_log(OS_LOG_DEFAULT, "%@: No match for funi entry", [self class]);
            notification = [[NSUserNotification alloc] init];
            notification.title = Funimation;
            notification.title = [NSString stringWithFormat:@"%@ newly added Funimation queue", title];

        }
        if (notification)
            [self _deliverFuniNotification:notification fromEntry:showEntry];
    }
}

- (void) _deliverFuniNotification: (NSUserNotification *)notif fromEntry:(NSDictionary *)newEntry
{
    NSImage *iconImage = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:newEntry[@"show"][@"image"]]];
    notif.contentImage = iconImage;
    //notif.userInfo = @{@"action_url":newEntry[@"url"]};
    
    os_log(OS_LOG_DEFAULT, "%@: Prepare to display notification: %{public}s", [self class], [notif.description UTF8String]);
    
    // Sanity check
    if (_shouldScan)
    {
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
    }
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
