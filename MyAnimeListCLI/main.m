//
//  main.m
//  MyAnimeListCLI
//
//  Created by Lucy Zhang on 8/28/17.
//  Copyright © 2017 Lucy Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <os/log.h>

#import "MALProtocol.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSXPCInterface *remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MALProtocol)];
        //NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        
        //NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithServiceName:bundleId];
        
        NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithMachServiceName:MALAgentID options:0];
        os_log(OS_LOG_DEFAULT, "MALCLI: Service name: %@",  xpcConnection.serviceName);
        xpcConnection.remoteObjectInterface = remoteInterface;
        
        xpcConnection.interruptionHandler = ^{
            NSLog(@"MALClI: Connection Terminated/Interrupted");
        };
        
        xpcConnection.invalidationHandler = ^{
            os_log(OS_LOG_DEFAULT, "MALCLI: Connection Invalidated");
        };
        
        [xpcConnection resume];
        
//        [xpcConnection.remoteObjectProxy setInvalidationHandler:^{
//            NSLog(@"Invalidated connection to MALDelegate");
//        }];
//        
//        [xpcConnection.remoteObjectProxy setInterruptionHandler:^{
//            NSLog(@"Interrupted connection to MALDelegate");
//        }];
        
        [[NSRunLoop currentRunLoop]run];

    }
    return 0;
}
