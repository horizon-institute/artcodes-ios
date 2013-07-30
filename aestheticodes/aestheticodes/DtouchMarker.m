//
//  DtouchMarker.m
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "DtouchMarker.h"

@interface DtouchMarker()
-(void)setCodeKey;
@end

@implementation DtouchMarker

@synthesize nodeIndex;
@synthesize occurence;
@synthesize code;
@synthesize codeKey;

-(id)init{
    self = [super init];
    if (self){
        self.occurence = 1;
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

@end
