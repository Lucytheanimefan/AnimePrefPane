//
//  AnimeRequester.m
//  Anime
//
//  Created by Lucy Zhang on 8/25/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "AnimeRequester.h"


const NSString *baseUrl = @"https://lucys-anime-server.herokuapp.com/";

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

- (void) makeGETRequest:(NSString *)endpoint withParameters:(nullable NSString *) params withCompletion:(void(^)(NSDictionary *))handler
{
    NSString *targetUrl = [NSString stringWithFormat:@"%@/%@?%@", baseUrl, endpoint, params];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                          options:NSJSONReadingAllowFragments
                                            error:&error];
          NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          //NSLog(@"Data received: %@", myString);
          handler(json);
      }] resume];
}
@end
