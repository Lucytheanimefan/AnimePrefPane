//
//  MALConnection.h
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MALConnection : NSObject

+ (id)sharedInstance;

-(void)startScanningForNotifications;

@end
