//
//  main.m
//  MyAnimeListAgent
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <os/log.h>

#import "MALDelegate.h"

int main(int argc, const char * argv[]) {
    
    //MALDelegate *myDelegate = [MALDelegate sharedDelegate];
    
    //NSXPCListener *listener =
    //[NSXPCListener serviceListener];
    
    //NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
 
    //[[NSRunLoop currentRunLoop] run];
    
    os_log(OS_LOG_DEFAULT, "Ready to return app");
    return NSApplicationMain(argc, argv);

}
