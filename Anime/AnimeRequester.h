//
//  AnimeRequester.h
//  Anime
//
//  Created by Lucy Zhang on 8/25/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimeRequester : NSObject

+ (id _Nonnull ) sharedInstance;

- (void) makeGETRequest:(NSString *_Nonnull)endpoint withParameters:(nullable NSString *) params withCompletion:(void(^)(NSDictionary *))handler;

@end
