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
#import "MarkerEmbeddedChecksumDetector.h"
#import <vector>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@interface MarkerEmbeddedChecksumDetector ()

-(MarkerRegion*)createChecksumRegionForNode:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy;
-(BOOL)isValidHollowDot:(int)currentDotIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy;

@end

@implementation MarkerEmbeddedChecksumDetector

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super initWithSettings:settings])
	{
		self.settings = settings;
		return self;
	}
	return nil;
}

-(Marker*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
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
				return nil;
			}
		}
		else
		{
			return nil;
		}
	}
	
	if (regions != nil)
	{
		[self sortRegions:regions];
		Marker* marker =[[MarkerWithEmbeddedChecksum alloc] initWithIndex:nodeIndex regions:regions embeddedChecksumRegion:checksumRegion];
		if([self isValidRegionList:marker])
		{
			return marker;
		}
	}
	return nil;
}

-(MarkerRegion*)createChecksumRegionForNode:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return nil; // There are no dots in this region.
	}
	
	// Count all the dots and check if they are leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidHollowDot:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get next dot node:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
		}
		else
		{
			return nil; // Dot is not a leaf in the hierarchy.
		}
	}
	
	return [[MarkerRegion alloc] initWithIndex:regionIndex value:dotCount];
}

-(BOOL)isValidHollowDot:(int)currentDotIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{	
	cv::Vec4i nodes = imageHierarchy.at(currentDotIndex);
	return nodes[CHILD_NODE_INDEX] >= 0 && // has a child node, and
	imageHierarchy.at((int) nodes[CHILD_NODE_INDEX])[NEXT_SIBLING_NODE_INDEX] < 0 && //the child has no siblings, and
	[self isValidLeaf:(int) nodes[CHILD_NODE_INDEX] inImageHierarchy:imageHierarchy];// the child is a leaf
}

-(BOOL)hasValidChecksum:(Marker*) marker
{
	if ([marker isKindOfClass:[MarkerWithEmbeddedChecksum class]])
	{
		MarkerWithEmbeddedChecksum* markerEc = (MarkerWithEmbeddedChecksum*) marker;
		if (markerEc.embeddedChecksumRegion!=nil)
		{
			// Find weighted sum of code, e.g. 1:1:2:4:4 -> 1*1 + 1*2 + 2*3 + 4*4 + 4*5 = 45
			// Although do not use weights/values divisible by 7
			// e.g. transform values 1,2,3,4,5,6,7,8, 9,10,11,12,13,14,15... to
			//                       1,2,3,4,5,6,8,9,10,11,12,13,15,16,17
			int embeddedChecksumModValue = 7;
			int weightedSum = 0;
			int weight = 1;
			
			for (MarkerRegion* region in marker.regions)
			{
				int value = (int) region.value;
				value += (value+value/embeddedChecksumModValue)/embeddedChecksumModValue;
				if (weight%embeddedChecksumModValue==0)
				{
					++weight;
				}
				weightedSum += value * weight++;
			}
			
			return markerEc.embeddedChecksumRegion.value == (weightedSum - 1) % 7 + 1;
		}
	}
	return [super hasValidChecksum:marker];
}

@end
