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

- (void) makeRequest:(NSString *)endpoint withParameters:(nullable NSString *) params postParams:(nullable NSDictionary *)postParams isPost:(BOOL)post withCompletion:(void(^)(NSDictionary *))handler;

@end
