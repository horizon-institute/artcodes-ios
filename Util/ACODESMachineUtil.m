//
//  ACODESMachineUtil.m
//  aestheticodes
//
//  Created by Will on 29/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ACODESMachineUtil.h"
#import <sys/utsname.h>

@implementation ACODESMachineUtil

+(NSString*) machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@end
