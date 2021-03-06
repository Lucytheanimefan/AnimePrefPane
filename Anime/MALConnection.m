//
//  MALConnection.m
//  Anime
//
//  Created by Lucy Zhang on 8/27/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import "MALConnection.h"

#import "MALProtocol.h"

#import <os/log.h>

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
    //NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    
    //NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithServiceName:bundleId];
    
    NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithMachServiceName:MALAgentID options:0];
    os_log(OS_LOG_DEFAULT, "%@: Service name: %@", [self class], xpcConnection.serviceName);
    xpcConnection.remoteObjectInterface = remoteInterface;
    
    xpcConnection.interruptionHandler = ^{
        NSLog(@"%@: Connection Terminated/Interrupted", [self class]);
    };
    
    xpcConnection.invalidationHandler = ^{
        os_log(OS_LOG_DEFAULT, "%@: Connection Invalidated", [self class]);
    };
    
    [xpcConnection resume];
    
    [xpcConnection.remoteObjectProxy setInvalidationHandler:^{
        NSLog(@"Invalidated connection to MALDelegate");
    }];
    
    [xpcConnection.remoteObjectProxy setInterruptionHandler:^{
        NSLog(@"Interrupted connection to MALDelegate");
    }];
    
    return xpcConnection;
}

-(void)startScanningForNotifications
{
    [[self.connection remoteObjectProxy] startScanningForNotifications];
}

- (void) setShouldScan:(BOOL)shouldScan
{
    [[self.connection remoteObjectProxy] setShouldScan:shouldScan];
}

@end
