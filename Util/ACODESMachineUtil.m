//
//  ACODESMachineUtil.m
//  aestheticodes
//
//  Created by Will on 29/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ACODESMachineUtil.h"
#import <sys/utsname.h>

@interface ACODESMachineUtil()

+ (bool)regexTestWith:(NSString*)modelRegex;

@end

@implementation ACODESMachineUtil

+(NSString*) machineName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+(bool) isIPhone1
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone1,1.*"];
}

+(bool) isIPhone3G
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone1,2.*"];
}

+(bool) isIPhone3GS
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone2.*"];
}

+(bool) isIPhone4
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone3.*"];
}

+(bool) isIPhone4S
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone4.*"];
}

+(bool) isIPhone4Series
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone[34].*"];
}

+(bool) isIPhone5
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone5.*"];
}

+(bool) isIPhone5S
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone6.*"];
}

+(bool) isIPhone5Series
{
    return [ACODESMachineUtil regexTestWith:@".*iPhone[56].*"];
}

+ (bool)regexTestWith:(NSString*)modelRegex;
{
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", modelRegex] evaluateWithObject:[ACODESMachineUtil machineName]];
}

@end
