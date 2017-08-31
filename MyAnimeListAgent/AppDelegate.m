//
//  AppDelegate.m
//  MyAnimeListAgent
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "AppDelegate.h"
#import "MALDelegate.h"

#import <os/log.h>


@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    os_log(OS_LOG_DEFAULT, "%@: App finished launching", [self class]);
    //    MALDelegate *myDelegate = [MALDelegate sharedDelegate];
    //    // Kick off listener
    //    NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:MALAgentID];
    //
    //    //NSXPCListener *listener = [NSXPCListener serviceListener];
    //
    //    listener.delegate = myDelegate;
    //    [listener resume];
    //
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    
    [self _startPeriodicTask];
    
    //});
    
    //[[NSRunLoop currentRunLoop] run];
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void) _startPeriodicTask
{
    // Schedule the background activity to scan for notifications periodically
    // Create an empty XPC dictionary
    xpc_object_t criteria = xpc_dictionary_create(NULL, NULL, 0);
    
    // Tell XPC that this is a repeating activity
    xpc_dictionary_set_bool(criteria, XPC_ACTIVITY_REPEATING, TRUE);
    
    // Set repeat interval
#ifdef DEBUG
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_INTERVAL, XPC_ACTIVITY_INTERVAL_1_MIN/2);
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_GRACE_PERIOD, 0);
#else
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_INTERVAL, 12*XPC_ACTIVITY_INTERVAL_1_HOUR );
    // Allow XPC to defer the activity by as much as 12 hours
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_GRACE_PERIOD, 12 * XPC_ACTIVITY_INTERVAL_1_HOUR);
#endif
    
    // Don't delay
    xpc_dictionary_set_int64(criteria, XPC_ACTIVITY_DELAY, 0);
    
    // Indicate that this is a user-invisible activity
    xpc_dictionary_set_string(criteria,XPC_ACTIVITY_PRIORITY, XPC_ACTIVITY_PRIORITY_UTILITY);//XPC_ACTIVITY_PRIORITY_MAINTENANCE);
    
    // Register the new XPC dictionary and pass it the handler block that performs the activity
    xpc_activity_register("com.lucy.MyAnimeListAgent.periodicTaskScheduler", criteria, ^(xpc_activity_t  _Nonnull activity) {
        os_log(OS_LOG_DEFAULT, "%@: Current state: %ld", [self class], xpc_activity_get_state(activity));
        /* do background or deferred work here */
        [[MALDelegate sharedDelegate] startScanningForNotifications];
    });

}


@end
