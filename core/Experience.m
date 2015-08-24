/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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
#import "Marker.h"
#import "Experience.h"
#import "MarkerCodeFactory.h"
#import "MarkerCodeFactoryAreaOrderExtension.h"
#import "MarkerCodeAreaOrientationOrderExtensionFactory.h"
#import "MarkerCodeOrientationAreaOrderExtensionFactory.h"
#import "MarkerCodeTouchingExtensionFactory.h"
#import "ACXGreyscaler.h"

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
		self.validationRegions = 0;
		self.validationRegionValue = 1;
		self.checksumModulo = 6;
		
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

/**
 * Check if a code is valid in this experience.
 * @param code			  The code, e.g. [1,1,2,4,4]
 * @param embeddedChecksum  An embedded checksum if found (this may make the order of the code important), otherwise pass nil.
 * @param reason			Pass in a mutable string for an English error message or nil if you do not want an error message.
 */
-(bool)isValid:(NSArray *)code withEmbeddedChecksum:(NSNumber*)embeddedChecksum reason:(NSMutableString *)reason
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
	else if (embeddedChecksum==nil && ![self hasValidCheckSum:code])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Sum of all dots must be divisible by checksum (%d)", self.checksumModulo]];
		return false;
	}
	else if (self.embeddedChecksum && embeddedChecksum!=nil && ![self hasValidEmbeddedCheckSum:code embeddedChecksum:embeddedChecksum])
	{
		[Experience setReason:reason to:[NSString stringWithFormat:@"Sum of all dots must be divisible by embedded checksum (%d)", [embeddedChecksum intValue]]];
		return false;
	}
	else if (!self.embeddedChecksum && embeddedChecksum!=nil)
	{
		[Experience setReason:reason to:@"Checksum error."];
		return false;
	}
	
	return true;
}


-(bool)isKeyValid:(NSString *)codeKey reason:(NSMutableString *)reason
{
	NSArray* codeStrings = [codeKey componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"+>"]];
	bool isPatternGroup = [codeKey rangeOfString:@"+"].location != NSNotFound;
	bool isPatternPath = [codeKey rangeOfString:@">"].location != NSNotFound;
	if (isPatternGroup && isPatternPath)
	{
		[reason setString:@"Can not use '+' and '>' in the same code."];
		return false;
	}
	
	for (NSString* codeString in codeStrings)
	{
		NSArray* array = [codeString componentsSeparatedByString:@":"];
		NSMutableArray* code = [[NSMutableArray alloc] init];
		for(NSString* part in array)
		{
			[code addObject:[[NSNumber alloc] initWithInteger:[part integerValue]]];
		}
		if (![self isValid:code withEmbeddedChecksum:nil reason:reason])
		{
			return false;
		}
	}
	
	return true;
}

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
	return YES;
}

-(NSString*)getNextUnusedMarker
{
	NSMutableArray* code;
	while (true)
	{
		code = [self getNextCode:code];
		if(code == nil)
		{
			return nil;
		}
			
		if ([self isValid:code withEmbeddedChecksum:nil reason:nil])
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
	}
	
	return nil;
}

-(NSMutableArray*)getNextCode:(NSMutableArray*)code
{
	if(!code)
	{
		int size = self.minRegions;
		NSMutableArray* code = [[NSMutableArray alloc] init];
		for (int index = 0; index < size; index++)
		{
			[code addObject:[NSNumber numberWithInt:1]];
		}
		return code;
	}
	
	int size = (int)[code count];
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
			if(size == self.maxRegions)
			{
				return nil;
			}
			else
			{
				size++;
				NSMutableArray* code = [[NSMutableArray alloc] init];
				for (int index = 0; index < size; index++)
				{
					[code addObject:[NSNumber numberWithInt:1]];
				}
				return code;
			}
		}
		else
		{
			NSNumber* number = [code objectAtIndex:i - 1];
			int value = number.intValue + 1;
			[code replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:value]];
		}
	}
	
	return code;
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

-(bool)hasValidEmbeddedCheckSum:(NSArray*)code embeddedChecksum:(NSNumber*)embeddedChecksum
{
	// Find weighted sum of code, e.g. 1:1:2:4:4 -> 1*1 + 1*2 + 2*3 + 4*4 + 4*5 = 45
	int weightedSum = 0;
	if ([code count] <= 20)
	{
		for (int i=0; i<[code count]; ++i)
		{
			weightedSum += [code[i] intValue] * (i+1);
		}
	}
	return [embeddedChecksum intValue] == (weightedSum%7 == 0 ? 7 : weightedSum%7);
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

-(MarkerCodeFactory*)getMarkerCodeFactory
{
	if (self.description != nil)
	{
		if ([self.description rangeOfString:@"AREA4321"].location != NSNotFound)
		{
			return [[MarkerCodeFactoryAreaOrderExtension alloc] init];
		}
		else if ([self.description rangeOfString:@"AO4321"].location != NSNotFound)
		{
			return [[MarkerCodeAreaOrientationOrderExtensionFactory alloc] init];
		}
		else if ([self.description rangeOfString:@"OA4321"].location != NSNotFound)
		{
			return [[MarkerCodeOrientationAreaOrderExtensionFactory alloc] init];
		}
		else if ([self.description rangeOfString:@"TOUCH4321"].location != NSNotFound)
		{
			return [[MarkerCodeTouchingExtensionFactory alloc] initWithChecksum:true orCombinedEmbeddedChecksum:false];
		}
		else if ([self.description rangeOfString:@"TOUCH-NOCHECKSUM-4321"].location != NSNotFound)
		{
			return [[MarkerCodeTouchingExtensionFactory alloc] initWithChecksum:false orCombinedEmbeddedChecksum:false];
		}
		else if ([self.description rangeOfString:@"TOUCH-EMCHECKSUM-4321"].location != NSNotFound)
		{
			return [[MarkerCodeTouchingExtensionFactory alloc] initWithChecksum:false orCombinedEmbeddedChecksum:true];
		}
	}
	return [[MarkerCodeFactory alloc] init];
}

-(ACXGreyscaler*)getImageGreyscaler
{
	if (self.greyscaleOptions==nil)
	{
		self.greyscaleOptions = @[@"RGB",@(0.299),@(0.587),@(0.114)];
	}
	
	if ([self.greyscaleOptions[0] rangeOfString:@"RGB"].location != NSNotFound)
	{
		return [[ACXGreyscalerRGB alloc] initWithHueShift:self.hueShift redMultiplier:[self.greyscaleOptions[1] doubleValue] greenMultiplier:[self.greyscaleOptions[2] doubleValue] blueMultiplier:[self.greyscaleOptions[3] doubleValue] invert:self.invertGreyscale];
	}
	else if ([self.greyscaleOptions[0] rangeOfString:@"CMYK"].location != NSNotFound)
	{
		return [[ACXGreyscalerCMYK alloc] initWithHueShift:self.hueShift C:[self.greyscaleOptions[1] doubleValue] M:[self.greyscaleOptions[2] doubleValue] Y:[self.greyscaleOptions[3] doubleValue] K:[self.greyscaleOptions[4] doubleValue] invert:self.invertGreyscale];
	}
	else if ([self.greyscaleOptions[0] rangeOfString:@"CMY"].location != NSNotFound)
	{
		return [[ACXGreyscalerCMY alloc] initWithHueShift:self.hueShift C:[self.greyscaleOptions[1] doubleValue] M:[self.greyscaleOptions[2] doubleValue] Y:[self.greyscaleOptions[3] doubleValue] invert:self.invertGreyscale];
	}
	return [[ACXGreyscalerRGB alloc] init];
}

-(bool)hasCodeBeginningWith:(NSString*)codeSubstring
{
	for (Marker* marker in self.markers)
	{
		if ([codeSubstring isEqualToString:[marker.code substringToIndex:MIN([codeSubstring length],[marker.code length])]])
		{
			return true;
		}
	}
	return false;
}

-(bool)isValidExceptChecksum:(NSArray *)code reason:(NSMutableString *)reason
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
	
	return true;
}

@end
