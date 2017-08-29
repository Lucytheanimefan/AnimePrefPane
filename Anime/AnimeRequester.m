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
- (void) makeRequest:(NSString *)endpoint withParameters:(nullable NSString *) params postParams:(nullable NSDictionary *)postParams isPost:(BOOL)post withCompletion:(void(^)(NSDictionary *))handler
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
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    if (post)
    {
        NSError *error;
        [request setHTTPMethod:@"POST"];
        NSData *postData = [NSJSONSerialization dataWithJSONObject:postParams
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        //NSData *postData = [params dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];//NSUTF8StringEncoding];
        [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
    }
    else
    {
        [request setHTTPMethod:@"GET"];
    }
    
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if (error)
          {
              os_log_error(OS_LOG_DEFAULT, "%@: Error making anime request: %@", [self class], error.description);
          }
          NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                          options:NSJSONReadingAllowFragments
                                            error:&error];
          //NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          //NSLog(@"Data received: %@", myString);
          handler(json);
      }] resume];
}

@end
