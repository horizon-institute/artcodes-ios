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
#import "ACXImageProcessor.h"
#import "ACXInvertComponent.h"
#import "ACXRgbComponent.h"
#import "ACXCmyComponent.h"
#import "ACXCmykComponent.h"
#import "ACXHlsEditComponent.h"
#import "ACXWhiteBalanceComponent.h"

@interface ACXImageProcessor ()

@property (retain) NSArray<id<ACXImageProcessingComponent>>* components;

@end

@implementation ACXImageProcessor

+ (NSArray<id<ACXImageProcessingComponent>>*) parseComponentsFrom:(NSArray<NSString*>*)strings
{
	NSMutableArray<id<ACXImageProcessingComponent>>* result = [[NSMutableArray alloc] initWithCapacity:[strings count]];
	if (strings!=nil)
	{
		for (NSString *componentString in strings)
		{
			id<ACXImageProcessingComponent> component = nil;
			if ([componentString isEqualToString:@"whiteBalance"])
			{
				component = [[ACXWhiteBalanceComponent alloc] init];
			}
			else if ([componentString hasPrefix:@"hlsEdit"])
			{
				NSError *error = NULL;
				NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"hlsEdit\\(([0-9]+),([0-9]+),([0-9]+)\\)"
																					   options:NSRegularExpressionCaseInsensitive
																						 error:&error];
				NSArray *matches = [regex matchesInString:componentString
												  options:0
													range:NSMakeRange(0, [componentString length])];
				
				if ([matches count] > 0)
				{
					NSTextCheckingResult *match = matches[0];
					NSRange hueRange = [match rangeAtIndex:1];
					NSRange lightnessRange = [match rangeAtIndex:2];
					NSRange saturationRange = [match rangeAtIndex:3];
					component = [[ACXHlsEditComponent alloc] initWithHue:[[componentString substringWithRange:hueRange] intValue] lightness:[[componentString substringWithRange:lightnessRange] intValue] saturation:[[componentString substringWithRange:saturationRange] intValue]];
				}
				else
				{
					NSLog(@"Could not parse HLS image processor '%@', ignoring.", componentString);
				}
			}
			else if ([componentString isEqualToString:@"invert"])
			{
				component = [[ACXInvertComponent alloc] init];
			}
			
			// RGB
			
			else if ([componentString isEqualToString:@"redRgbFilter"])
			{
				component = [[ACXRgbComponent alloc] initWithChannel:ACXRgbChannelRed];
			}
			else if ([componentString isEqualToString:@"greenRgbFilter"])
			{
				component = [[ACXRgbComponent alloc] initWithChannel:ACXRgbChannelGreen];
			}
			else if ([componentString isEqualToString:@"blueRgbFilter"])
			{
				component = [[ACXRgbComponent alloc] initWithChannel:ACXRgbChannelBlue];
			}
			
			// CMY
			
			else if ([componentString isEqualToString:@"cyanCmyFilter"])
			{
				component = [[ACXCmyComponent alloc] initWithChannel:ACXCmyChannelCyan];
			}
			else if ([componentString isEqualToString:@"magentaCmyFilter"])
			{
				component = [[ACXCmyComponent alloc] initWithChannel:ACXCmyChannelMagenta];
			}
			else if ([componentString isEqualToString:@"yellowCmyFilter"])
			{
				component = [[ACXCmyComponent alloc] initWithChannel:ACXCmyChannelYellow];
			}
			
			// CMYK
			
			else if ([componentString isEqualToString:@"cyanCmykFilter"])
			{
				component = [[ACXCmykComponent alloc] initWithChannel:ACXCmykChannelCyan];
			}
			else if ([componentString isEqualToString:@"magentaCmykFilter"])
			{
				component = [[ACXCmykComponent alloc] initWithChannel:ACXCmykChannelMagenta];
			}
			else if ([componentString isEqualToString:@"yellowCmykFilter"])
			{
				component = [[ACXCmykComponent alloc] initWithChannel:ACXCmykChannelYellow];
			}
			else if ([componentString isEqualToString:@"blackCmykFilter"])
			{
				component = [[ACXCmykComponent alloc] initWithChannel:ACXCmykChannelBlack];
			}
			
			// ERROR
			
			else
			{
				NSLog(@"Unknown image processor '%@', ignoring.", componentString);
			}
			
			if (component!=nil)
			{
				[result addObject:component];
			}
		}
	}
	return result;
}

- (id) initWithComponents:(NSArray<id<ACXImageProcessingComponent>>*)components
{
	if (self = [super init])
	{
		self.components = components;
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) processWithBuffer:(ACXBufferManager*)buffer
{
	if (self.components!=nil)
	{
		for (id<ACXImageProcessingComponent> component in self.components)
		{
			[component process:buffer];
		}
	}
}

- (void) releaseResources
{
	if (self.components!=nil)
	{
		for (id<ACXImageProcessingComponent> component in self.components)
		{
			[component releaseResources];
		}
	}
}

@end
