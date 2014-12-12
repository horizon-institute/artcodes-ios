//
//  Experience.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//
// TODO Add validation for partial marker codes

#import "Marker.h"
#import "Experience.h"

@implementation Experience

@synthesize description;

-(instancetype)init
{
	self = [super init];
	if(self)
	{
		self.markers = (NSMutableArray<Marker>*)[[NSMutableArray alloc] init];
		self.minRegions = 5;
		self.maxRegions = 5;
		self.maxEmptyRegions = 0;
		self.maxRegionValue = 6;
		self.validationRegions = 2;
		self.validationRegionValue = 1;
		self.checksumModulo = 6;
		
		self.minimumContourSize = 50;
		self.maximumContoursPerFrame = 15000;
		self.thresholdBehaviour = @"default";
		self.version = 1;
	}
	return self;
}

-(Marker*)getMarker:(NSString *)codeKey
{
	for(Marker* action in self.markers)
	{
		if([action.code isEqualToString:codeKey])
		{
			return action;
		}
	}
	
	return nil;
}


/** This is a helper function to make [self isValid] more readable */
+(void)setReason:(NSMutableString*)container to:(NSString*)error
{
	if (container != nil) {
		[container setString:error];
	}
}

-(bool)isValid:(NSArray *)code reason:(NSMutableString *)reason
{
	if (![self hasValidNumberOfRegions:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Wrong number of regions (%lu), there must be %@ regions", (unsigned long)[code count], self.minRegions==self.maxRegions?[NSString stringWithFormat:@"%d",self.minRegions]:[NSString stringWithFormat:@"%d-%d",self.minRegions, self.maxRegions]]];
		return false;
	}
	else if (![self hasValidNumberOfEmptyRegions:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Too many empty regions, there can be upto %d empty regions",self.maxEmptyRegions]];
		return false;
	}
	else if (![self hasValidNumberOfLeaves:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Too many dots, there can only be %d dots in a region",self.maxRegionValue]];
		return false;
	}
	else if (![self hasValidationRegions:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Validation regions required, %d regions must be %d",self.validationRegions, self.validationRegionValue]];
		return false;
	}
	else if (![self hasValidCheckSum:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Sum of all dots must be divisible by checksum (%d)", self.checksumModulo]];
		return false;
	}
	
	return true;
}


-(bool)isKeyValid:(NSString *)codeKey reason:(NSMutableString *)reason
{
	NSArray* array = [codeKey componentsSeparatedByString:@":"];
	NSMutableArray* code = [[NSMutableArray alloc] init];
	for(NSString* part in array)
	{
		[code addObject:[[NSNumber alloc] initWithInteger:[part integerValue]]];
	}
	return [self isValid:code reason:reason];
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
	return YES;
}

-(NSString*)getNextUnusedMarker
{
	for (int size = self.minRegions; size <= self.maxRegions; size++)
	{
		NSMutableArray* code = [[NSMutableArray alloc] init];
		for (int index = 0; index < size; index++)
		{
			[code addObject:[NSNumber numberWithInt:1]];
		}
		
		while (true)
		{
			if ([self isValid:code reason:nil])
			{
				NSMutableString* codeStr = [[NSMutableString alloc] init];
				
				for (int i =0; i < code.count; i++)
				{
					if (i > 0)
					{
						[codeStr appendFormat:@":%d", [[code objectAtIndex:i] intValue]];
					}
					else
					{
						codeStr = [[NSMutableString alloc] init];
						[codeStr appendFormat:@"%d", [[code objectAtIndex:i] intValue]];
					}
				}
				
				NSString* marker = [NSString stringWithString:codeStr];
				NSLog(@"marker %@", marker);
				bool found = false;
				for(Marker* action in self.markers)
				{
					if([action.code isEqualToString:marker])
					{
						found = true;
						break;
					}
				}
				
				if(!found)
				{
					return marker;
				}
			}
			
			for (int i = (size - 1); i >= 0; i--)
			{
				NSNumber* number = [code objectAtIndex:i];
				int value = number.intValue + 1;
				[code replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:value]];
				if (value <= self.maxRegionValue)
				{
					break;
				}
				else if (i == 0)
				{
					return nil;
				}
				else
				{
					NSNumber* number = [code objectAtIndex:i - 1];
					int value = number.intValue + 1;
					[code replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:value]];
				}
			}
		}
	}
	
	return nil;
}

-(bool)hasValidationRegions:(NSArray*) code
{
	if(self.validationRegions == 0)
	{
		return true;
	}
	
	int validRegions = 0;
	for(NSNumber* value in code)
	{
		if(value.intValue == self.validationRegionValue)
		{
			validRegions++;
		}
	}
	
	return validRegions >= self.validationRegions;
}

-(bool)hasValidCheckSum:(NSArray*) code
{
	if(self.checksumModulo <= 1)
	{
		return true;
	}
	int total = 0;
	for(NSNumber* value in code)
	{
		total += value.intValue;
	}
	return (total % self.checksumModulo) == 0;
}

-(bool) hasValidNumberOfRegions:(NSArray*) code
{
	return (code.count >= self.minRegions) && (code.count <= self.maxRegions);
}

-(bool) hasValidNumberOfEmptyRegions:(NSArray*) code
{
	int emptyRegions = 0;
	
	for(NSNumber* value in code)
	{
		if (value.intValue == 0)
		{
			emptyRegions++;
		}
	}
	return emptyRegions <= self.maxEmptyRegions;
}

-(bool) hasValidNumberOfLeaves:(NSArray*) code
{
	for(NSNumber* value in code)
	{
		if (value.intValue > self.maxRegionValue)
		{
			return false;
		}
	}
	
	return true;
}

@end
