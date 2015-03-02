/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import "MarkerCode.h"

@interface MarkerCode()
@property NSMutableArray* nodeIndexes;
@end

@implementation MarkerCode

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
		codeKey = [MarkerCode getCodeKey: code];
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