//
//  DtouchMarker.m
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "DtouchMarker.h"

@interface DtouchMarker()
@property NSMutableDictionary* nodeIndexes;
-(void)setCodeKey;
@end

@implementation DtouchMarker

@synthesize code;
@synthesize codeKey;
@synthesize nodeIndexes;
@synthesize totalNumberOfBranches;
@synthesize totalNumberOfEmptyBranches;

-(id)init{
    self = [super init];
    if (self){
        nodeIndexes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)setCode:(NSArray *)inCode{
    if (inCode.count > 0)
    {
        code = [[inCode copy] sortedArrayUsingSelector:@selector(compare:)];
        [self setCodeKey];
    }
}

-(NSArray*)code{
    return code;
}

-(void)setCodeKey{
    NSMutableString* codeStr;
    
    for (int i =0; i < code.count; i++){
        if (i > 0)
            [codeStr appendFormat:@":%d", [[code objectAtIndex:i] integerValue]];
        else
        {
            codeStr = [[NSMutableString alloc] init];
            [codeStr appendFormat:@"%d", [[code objectAtIndex:i] integerValue]];
        }
    }
    
    if (codeStr != nil)
        codeKey = [codeStr copy];
}

-(void)addNodeIndex:(int)nodeIndex{
    NSString* key = [NSString stringWithFormat:@"%d",nodeIndex];
    if ([nodeIndexes objectForKey:key] == nil){
        [nodeIndexes setObject:[NSNumber numberWithInt:nodeIndex] forKey:key];
    }
}

-(void)removeNodeIndex:(int)nodeIndex{
    NSString* key = [NSString stringWithFormat:@"%d",nodeIndex];
    [nodeIndexes removeObjectForKey:key];
}

-(NSArray*)getNodeIndexes{
    return [nodeIndexes allValues];
}

-(int)totalNumberOfBranches{
    return [self.code count];
}

-(int)totalNumberOfEmptyBranches{
    int numberOfEmptyBranches = 0;
    
    for (NSNumber* leaves in self.code){
        if ([leaves intValue] == 0)
            numberOfEmptyBranches++;
    }
    return numberOfEmptyBranches;
}

@end
