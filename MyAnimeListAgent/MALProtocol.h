//
//  MALProtocol.h
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

// NSXPC Protocol to implement

#define MALAgentID @"com.lucy.MyAnimeListAgent"


@protocol MALProtocol <NSObject>

- (void) startScanningForNotifications;

- (void) setShouldScan:(BOOL)shouldScan;

@end
