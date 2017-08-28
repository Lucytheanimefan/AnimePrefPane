//
//  AppDelegate.m
//  MyAnimeListAgent
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "AppDelegate.h"

#import <os/log.h>

#import "MALDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    os_log(OS_LOG_DEFAULT, "%@: App finished launching", [self class]);
    [[MALDelegate sharedDelegate] startScanningForNotifications];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
