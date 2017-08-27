//
//  main.m
//  MyAnimeListAgent
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MALDelegate.h"

int main(int argc, const char * argv[]) {
    
    MALDelegate *myDelegate = [MALDelegate sharedDelegate];
    
    NSXPCListener *listener =
    [NSXPCListener serviceListener];
    
    listener.delegate = myDelegate;
    [listener resume];
 
    
    return NSApplicationMain(argc, argv);
}
