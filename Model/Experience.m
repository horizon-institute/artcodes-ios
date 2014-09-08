//
//  Experience.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//
// TODO Add validation for partial marker codes

#import "MarkerAction.h"
#import "Experience.h"

@implementation Experience

-(instancetype)init
{
    self = [super init];
	if(self)
	{
		self.markers = (NSMutableArray<MarkerAction>*)[[NSMutableArray alloc] init];
		self.modes = [[NSArray alloc] init];
		self.minRegions = 5;
		self.maxRegions = 5;
		self.maxEmptyRegions = 0;
		self.maxRegionValue = 6;
		self.validationRegions = 2;
		self.validationRegionValue = 1;
		self.checksumModulo = 6;
		self.editable = true;
		self.addMarkers = true;
		self.changed = false;
		self.updateURL = @"http://www.wornchaos.org/settings.json";
        
        self.minimumContourSize = 50;
        self.maximumContoursPerFrame = 15000;
        self.thresholdBehaviour = @"default";
	}
	return self;
}

-(MarkerAction*)getMarker:(NSString *)codeKey
{
	for(MarkerAction* action in self.markers)
	{
		if([action.code isEqualToString:codeKey])
		{
			return action;
		}
	}
	
	return nil;
}

-(bool)isValid:(NSArray *)code
{
	return [self hasValidNumberOfRegions:code]
		&& [self hasValidNumberOfEmptyRegions:code]
		&& [self hasValidNumberOfLeaves:code]
		&& [self hasValidationRegions:code]
		&& [self hasValidCheckSum:code];
}

-(bool)isKeyValid:(NSString *)codeKey
{
	NSArray* array = [codeKey componentsSeparatedByString:@":"];
	NSMutableArray* code = [[NSMutableArray alloc] init];
	for(NSString* part in array)
	{
		[code addObject:[[NSNumber alloc] initWithInteger:[part integerValue]]];
	}
	return [self isValid:code];
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
	return YES;
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

-(void)setIntValue:(long)value key:(NSString *)key
{
	if([self respondsToSelector:NSSelectorFromString(key)])
	{
		[self valueForKey:key];
		if([[self valueForKey:key] isKindOfClass:[NSNumber class]])
		{
			long current = [[self valueForKey:key] longValue];
			if(current != value)
			{
				[self setValue:[[NSNumber alloc] initWithLong:value] forKey:key];
				self.changed = true;
			}
		}
	}
}

@end