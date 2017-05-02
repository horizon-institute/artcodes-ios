/*
 * Artcodes recognises a different marker scheme that allows the
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

#import "ImageProcessorRegistory.h"

#import "IntensityFilter.h"
#import "InvertFilter.h"
#import "WhiteBalanceFilter.h"
#import "HlsEditFilter.h"
#import "RgbColourFilter.h"
#import "CmykColourFilter.h"

#import "TileThreshold.h"
#import "OtsuThreshold.h"

#import "MarkerDetector.h"
#import "MarkerEmbeddedChecksumDetector.h"
#import "MarkerAreaOrderDetector.h"
#import "MarkerEmbeddedChecksumAreaOrderDetector.h"

#import "DebugMarkerDetector.h"


@interface ImageProcessorRegistory()
@property NSMutableDictionary* factoryRegistry;
@end

@implementation ImageProcessorRegistory

+(ImageProcessorRegistory*) sharedInstance
{
	static ImageProcessorRegistory *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[ImageProcessorRegistory alloc] init];
		sharedInstance.factoryRegistry = [[NSMutableDictionary alloc] init];
		
		[sharedInstance registerFactory:[[IntensityFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[InvertFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[WhiteBalanceFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[HlsEditFilterFactory alloc] init]];
		
		[sharedInstance registerFactory:[[RedRgbFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[GreenRgbFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[BlueRgbFilterFactory alloc] init]];
		
		[sharedInstance registerFactory:[[CyanCmykFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[MagentaCmykFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[YellowCmykFilterFactory alloc] init]];
		[sharedInstance registerFactory:[[BlackCmykFilterFactory alloc] init]];
		
		[sharedInstance registerFactory:[[TileThresholdFactory alloc] init]];
		[sharedInstance registerFactory:[[OtsuThresholdFactory alloc] init]];
		
		[sharedInstance registerFactory:[[MarkerDetectorFactory alloc] init]];
		[sharedInstance registerFactory:[[MarkerEmbeddedChecksumDetectorFactory alloc] init]];
		[sharedInstance registerFactory:[[MarkerAreaOrderDetectorFactory alloc] init]];
		[sharedInstance registerFactory:[[MarkerEmbeddedChecksumAreaOrderDetectorFactory alloc] init]];
		
		[sharedInstance registerFactory:[[DebugMarkerDetectorFactory alloc] init]];
		
	});
	return sharedInstance;
}

-(void) registerFactory:(id<ImageProcessorFactory>)factory
{
	[self.factoryRegistry setObject:factory forKey:[factory name]];
}

-(id<ImageProcessor>) getProcessorForString:(NSString*)string WithSettings:(DetectionSettings*)settings
{
	NSDictionary* processorDetails = [ImageProcessorRegistory parsePipelineString:string];
	NSString* processorName = processorDetails[@"name"];
	NSDictionary* processorArgs = processorDetails[@"args"];
	
	id<ImageProcessorFactory> factory = [self.factoryRegistry objectForKey:processorName];
	
	if (factory != nil)
	{
		return [factory createWithSettings:settings arguments:processorArgs];
	}
	
	return nil;
}

+(NSDictionary*) parsePipelineString:(NSString*)pipelineString
{
	NSString* regexString =@"([^\\(\\)]+)(?:\\(([^\\(\\)]*)\\))?";
	NSRegularExpressionOptions options = NSRegularExpressionCaseInsensitive;
	NSError* error = NULL;
	
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regexString options:options error:&error];
	if (error)
	{
		NSLog(@"%@", [error description]);
	}
	else
	{
		NSTextCheckingResult* match = [regex firstMatchInString:pipelineString options:0 range:NSMakeRange(0, [pipelineString length])];
		if (match) {
			NSString* pipelineItemName = [pipelineString substringWithRange:[match rangeAtIndex:1]];
			NSRange pipelineArgsRange = [match rangeAtIndex:2];
			NSString* pipelineArgsString = @"";
			if (pipelineArgsRange.length>0)
			{
				pipelineArgsString = [pipelineString substringWithRange:pipelineArgsRange];
			}
			return @{@"name":pipelineItemName, @"args":[ImageProcessorRegistory parseDictionaryFrom:pipelineArgsString]};
		}
	}
	return @{@"name":@"", @"args":@{}};
}
+(NSDictionary*) parseDictionaryFrom:(NSString*)string
{
	NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
	if (string != nil)
	{
		for (NSString* argStr in [[string stringByTrimmingCharactersInSet:
								   [NSCharacterSet whitespaceCharacterSet]] componentsSeparatedByString:@","])
		{
			NSArray* argArray = [argStr componentsSeparatedByString:@"="];
			if ([argArray count]==1)
			{
				dictionary[argStr] = argStr;
			}
			else if ([argArray count]>=2)
			{
				dictionary[[argArray[0] stringByTrimmingCharactersInSet:
					  [NSCharacterSet whitespaceCharacterSet]]] = [argArray[1] stringByTrimmingCharactersInSet:
																   [NSCharacterSet whitespaceCharacterSet]];
			}
		}
	}
	return dictionary;
}

@end
