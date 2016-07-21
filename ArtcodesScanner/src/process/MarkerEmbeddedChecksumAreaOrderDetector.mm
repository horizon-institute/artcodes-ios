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

#import "MarkerEmbeddedChecksumAreaOrderDetector.h"
#import <vector>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@implementation MarkerEmbeddedChecksumAreaOrderDetector


-(Marker*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy andImageContour:(std::vector<std::vector<cv::Point> >&)contours
{
	NSMutableArray* regions = nil;
	MarkerRegion* checksumRegion = nil;
	
	// Loop through the regions, verifing the value of each:
	for (int currentRegionIndex = imageHierarchy.at(nodeIndex)[CHILD_NODE_INDEX]; currentRegionIndex >= 0; currentRegionIndex = imageHierarchy.at(currentRegionIndex)[NEXT_SIBLING_NODE_INDEX])
	{
		MarkerRegion* region = [self createRegionForNode:currentRegionIndex inImageHierarchy:imageHierarchy];
		if(region != nil)
		{
			if (self.settings.ignoreEmptyRegions && region.value==0)
			{
				continue;
			}
			else if(regions == nil)
			{
				regions = [[NSMutableArray alloc] init];
			}
			else if(regions.count >= self.settings.maxRegions)
			{
				// Too many regions.
				return nil;
			}
			[regions addObject:region];
		}
		else if (checksumRegion==nil)
		{
			checksumRegion = [self createChecksumRegionForNode:currentRegionIndex inImageHierarchy:imageHierarchy];
			if (checksumRegion == nil)
			{
				// Too many regions.
				return nil;
			}
		}
		else
		{
			// Too many regions.
			return nil;
		}
	}
	
	if (regions != nil && checksumRegion!=nil)
	{
		[regions sortUsingComparator:^NSComparisonResult(id a, id b) {
			NSInteger first = ((MarkerRegion*)a).value;
			NSInteger second = ((MarkerRegion*)b).value;
			return [@(first) compare:@(second)];
		}];
		Marker* marker = [[MarkerWithEmbeddedChecksum alloc] initWithIndex:nodeIndex regions:regions embeddedChecksumRegion:checksumRegion];
		if([self isValidRegionList:marker])
		{
			[self addAreasToRegions:regions andImageContour:contours];
			[self sortRegions:regions];
			return [[MarkerWithEmbeddedChecksum alloc] initWithIndex:nodeIndex regions:regions embeddedChecksumRegion:checksumRegion];
		}
		else
		{
			// Too many regions.
			return nil;
		}
	}
	return nil;
}

-(void)addAreasToRegions:(NSMutableArray*)regions andImageContour:(std::vector<std::vector<cv::Point> >&)contours
{
	for (MarkerRegion* region in regions)
	{
		double area = cv::contourArea(contours.at(region.index));
		region.data = @(area);
	}
}

-(void)sortRegions:(NSMutableArray*) regions
{
	[regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		NSNumber *first = ((MarkerRegion*)a).data;
		NSNumber *second = ((MarkerRegion*)b).data;
		return [first compare:second];
	}];
}

@end
