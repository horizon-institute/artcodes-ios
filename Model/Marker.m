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
@end

@implementation Marker

@synthesize code;
@synthesize codeKey;
@synthesize occurence;
@synthesize nodeIndexes;
@synthesize regionCount;
@synthesize emptyRegionCount;

+(NSString*)getCodeKey:(NSArray*)code
{
	NSMutableString* codeStr;
	
	for (int i =0; i < code.count; i++)
	{
		if (i > 0)
		{
			[codeStr appendFormat:@":%ld", (long)[[code objectAtIndex:i] integerValue]];
		}
		else
		{
			codeStr = [[NSMutableString alloc] init];
			[codeStr appendFormat:@"%ld", (long)[[code objectAtIndex:i] integerValue]];
		}
	}
	
	return codeStr;
}

-(id)init
{
    self = [super init];
    if (self)
	{
        nodeIndexes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCode:(NSArray*)codeArray andKey:(NSString*)key
{
	self = [super init];
	if(self)
	{
        nodeIndexes = [[NSMutableArray alloc] init];
		code = codeArray;
		codeKey = key;
	}
	return self;
}

-(void)setCode:(NSArray *)inCode
{
    if (inCode.count > 0)
    {
        code = [inCode sortedArrayUsingSelector:@selector(compare:)];
		codeKey = [Marker getCodeKey: code];
    }
}

-(NSArray*)code
{
    return code;
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