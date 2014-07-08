//
//  DtouchMarker.m
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "Marker.h"

@interface Marker()
@property NSMutableArray* nodeIndexes;
-(void)setCodeKey;
@end

@implementation Marker

@synthesize code;
@synthesize codeKey;
@synthesize nodeIndexes;
@synthesize regionCount;
@synthesize emptyRegionCount;

-(id)init
{
    self = [super init];
    if (self){
        nodeIndexes = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setCode:(NSArray *)inCode
{
    if (inCode.count > 0)
    {
        code = [inCode sortedArrayUsingSelector:@selector(compare:)];
        [self setCodeKey];
    }
}

-(NSArray*)code
{
    return code;
}

-(void)setCodeKey
{
    NSMutableString* codeStr;
    
    for (int i =0; i < code.count; i++){
        if (i > 0)
            [codeStr appendFormat:@":%ld", (long)[[code objectAtIndex:i] integerValue]];
        else
        {
            codeStr = [[NSMutableString alloc] init];
            [codeStr appendFormat:@"%ld", (long)[[code objectAtIndex:i] integerValue]];
        }
    }
    
    if (codeStr != nil)
        codeKey = [codeStr copy];
}

-(int)regionCount
{
    return (int)[self.code count];
}

-(int)emptyRegionCount
{
    int numberOfEmptyBranches = 0;
    
    for (NSNumber* leaves in self.code){
        if ([leaves intValue] == 0)
            numberOfEmptyBranches++;
    }
    return numberOfEmptyBranches;
}

@end