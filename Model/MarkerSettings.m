//
//  MarkerSettings.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//
// TODO Add validation for partial marker codes

#import "MarkerAction.h"
#import "MarkerSettings.h"

@implementation MarkerSettings

+ (MarkerSettings*)settings
{
    static MarkerSettings *sharedSettings = nil;
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            sharedSettings = [[self alloc] init];
		}
    }
    return sharedSettings;
}

-(instancetype)init
{
    self = [super init];
	if(self)
	{
		self.markers = [[NSMutableDictionary alloc] init];
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

-(void)load:(NSDictionary *)data
{
	NSArray* markerArray = [data valueForKey:@"markers"];
	for (NSDictionary* markerDict in markerArray)
	{
		MarkerAction* action = [[MarkerAction alloc] init];
		[action load:markerDict];
		[self.markers setObject:action forKey:action.code];
	}

	NSArray* modeArray = [data valueForKey:@"modes"];
	NSLog(@"Loading");
	for(NSString* mode in modeArray)
	{
		NSLog(@"Adding Mode: %@", mode);
	}
	
	self.modes = modeArray;

	for (NSString* mode in self.modes)
	{
		NSLog(@"Mode: %@", mode);
	}
	
	self.minRegions = (int)[data[@"minRegions"] integerValue];
	self.maxRegions = (int)[data[@"maxRegions"] integerValue];
	self.maxRegionValue = (int)[data[@"maxRegionValue"] integerValue];
	self.maxEmptyRegions = (int)[data[@"maxEmptyRegions"] integerValue];
	
	self.validationRegions = (int)[data[@"validationRegions"] integerValue];
	self.validationRegionValue = (int)[data[@"validationRegionValue"] integerValue];
	self.checksumModulo = (int)[data[@"checksumModulo"] integerValue];
    
    if (data[@"minimumContourSize"])
        self.minimumContourSize = (int)[data[@"minimumContourSize"] integerValue];
    if (data[@"maximumContoursPerFrame"])
        self.maximumContoursPerFrame = (int)[data[@"maximumContoursPerFrame"] integerValue];
    if (data[@"thresholdBehaviour"])
        self.thresholdBehaviour = data[@"thresholdBehaviour"];
	
	self.changed = false;
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
	if(self.checksumModulo == 0)
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

-(NSDictionary*)toDictionary
{
	NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
	
	NSMutableArray* markerArray = [[NSMutableArray alloc] init];
	for (NSString* code in self.markers)
	{
		MarkerAction* action = [self.markers objectForKey:code];
		[markerArray addObject:action.toDictionary];
	}
	
	[result setValue:markerArray forKey:@"markers"];
	[result setValue:self.modes forKey:@"modes"];

	[result setValue:[NSNumber numberWithInt:self.minRegions] forKey:@"minRegions"];
	[result setValue:[NSNumber numberWithInt:self.maxRegions] forKey:@"maxRegions"];
	[result setValue:[NSNumber numberWithInt:self.maxRegionValue] forKey:@"maxRegionValue"];
	[result setValue:[NSNumber numberWithInt:self.maxEmptyRegions] forKey:@"maxEmptyRegions"];
	
	[result setValue:[NSNumber numberWithInt:self.validationRegions] forKey:@"validationRegions"];
	[result setValue:[NSNumber numberWithInt:self.validationRegionValue] forKey:@"validationRegionValue"];
	[result setValue:[NSNumber numberWithInt:self.checksumModulo] forKey:@"checksumModulo"];
	
	return result;
}

@end
