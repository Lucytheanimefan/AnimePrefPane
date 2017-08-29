//
//  AnimeRequester.m
//  Anime
//
//  Created by Lucy Zhang on 8/25/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "AnimeRequester.h"

#import <os/log.h>

const NSString *baseUrl = @"https://lucys-anime-server.herokuapp.com";

@implementation AnimeRequester

+ (id) sharedInstance
{
    static AnimeRequester *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

// params is already formatted for the url
- (void) makeRequest:(NSString *)endpoint withParameters:(nullable NSString *) params isPost:(BOOL)post withCompletion:(void(^)(NSDictionary *))handler
{
    NSString *targetUrl;
    
    if (post)
    {
        targetUrl = [NSString stringWithFormat:@"%@/%@", baseUrl, endpoint];
    }
    else
    {
        targetUrl = [NSString stringWithFormat:@"%@/%@?%@", baseUrl, endpoint, params];
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    if (post)
    {
        [request setHTTPMethod:@"POST"];
        //[request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData *postData = [params dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:postData];
    }
    else{
        [request setHTTPMethod:@"GET"];
    }
    
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if (error)
          {
              os_log(OS_LOG_ERROR, "%@: Error making anime request: %@", [self class], error.description);
          }
          NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                          options:NSJSONReadingAllowFragments
                                            error:&error];
          NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          NSLog(@"Data received: %@", myString);
          handler(json);
      }] resume];
}

@end
