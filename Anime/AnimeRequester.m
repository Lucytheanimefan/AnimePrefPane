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

- (void) makeGETRequest
{
    NSString *targetUrl = [NSString stringWithFormat:@"%@/init", baseUrl];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:targetUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          
          NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
          NSLog(@"Data received: %@", myString);
      }] resume];
}
@end
