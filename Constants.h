//
//  Constants.h
//  Anime
//
//  Created by Lucy Zhang on 8/28/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>


#define AnimeNotificationCenter @"AnimeNotificationCenter"
#define MALAgentCenter @"MALAgentCenter"
#define FuniAgentCenter @"FunimationAgentCenter"

#define MAL @"MyAnimeList"
#define CrunchyRoll @"Crunchyroll"
#define Funimation @"Funimation"

#define AnimeAppID @"com.lucy.anime"

extern NSString * const malEntries;
extern NSString * const funiQueue;
extern NSString * const CRProfile;
extern NSString * const funiUsernameKey;
extern NSString * const funiPasswordKey;
extern NSString * const crUsernameKey;
extern NSString * const malUsernameKey;

@interface Constants : NSObject

@end
