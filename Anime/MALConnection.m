//
//  MALConnection.m
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "MALConnection.h"

#import "MALProtocol.h"

@interface MALConnection()

@property (nonatomic, readwrite) NSXPCConnection *connection;

@end

@implementation MALConnection

+ (id)sharedInstance
{
    static MALConnection *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (NSXPCConnection *)connection
{
    if (!_connection)
    {
        _connection = [self _xpcConnection];
    }
    return _connection;
}

- (NSXPCConnection *) _xpcConnection
{
    NSXPCInterface *remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MALProtocol)];
    NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"com.lucy.anime"];
    
    xpcConnection.remoteObjectInterface = remoteInterface;
    
    xpcConnection.interruptionHandler = ^{
        NSLog(@"Connection Terminated");
    };
    
    xpcConnection.invalidationHandler = ^{
        NSLog(@"Connection Invalidated");
    };
    
    [xpcConnection resume];
    
    [self.connection.remoteObjectProxy setInvalidationHandler:^{
        NSLog(@"Invalidated connection to MALDelegate");
    }];
    
    [self.connection.remoteObjectProxy setInterruptionHandler:^{
        NSLog(@"Interrupted connection to MALDelegate");
    }];
    
    return xpcConnection;
}

-(void)startScanningForNotifications
{
    [self.connection.remoteObjectProxy startScanningForNotifications];
}

@end
