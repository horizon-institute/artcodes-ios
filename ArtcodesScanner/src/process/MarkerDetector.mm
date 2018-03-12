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
#import "MarkerDetectorExtension.h"
#import <vector>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>
#import "SceneDetails.h"
#import "ImageBuffers.h"

int const CHILD_NODE_INDEX = 2;
int const NEXT_SIBLING_NODE_INDEX = 0;

@implementation MarkerDetectorFactory

-(NSString*) name
{
	return @"detect";
}

-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[MarkerDetector alloc] initWithSettings:settings];
}

@end

@implementation MarkerDetector

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		self.settings = settings;
		return self;
	}
	return nil;
}

-(bool) requiresBgraInput
{
	return false;
}

-(void) process:(ImageBuffers*) buffers
{
	std::vector<std::vector<cv::Point> > contours;
	std::vector<cv::Vec4i> hierarchy;
	cv::findContours(buffers.imageInGrey, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	//detect markers
	NSArray<Marker*>* markers = [self findMarkers:hierarchy andImageContour:contours andBuffers:buffers];
	
	self.settings.detected = markers.count > 0;
	if(self.settings.handler != nil)
	{
		[self.settings.handler onMarkersDetected:markers scene:[[SceneDetails alloc] initWithContours:contours hierarchy:hierarchy sourceImageSize:[[ImageSize alloc] initWithMat:buffers.imageInGrey]]];
	}
}

-(NSArray<Marker*>*)findMarkers:(std::vector<cv::Vec4i>&)hierarchy andImageContour:(std::vector<std::vector<cv::Point> >&)contours andBuffers:(ImageBuffers*) buffers
{
	double diagonalSize = sqrt(pow(buffers.image.cols, 2) + pow(buffers.image.rows, 2));
	
	/*! Detected markers */
	NSMutableArray<Marker*>* markers = [[NSMutableArray alloc] init];
	//int skippedContours = 0;
	
	//NSLog(@"Contours %lu", contours.size());
	for (int i = 0; i < contours.size(); i++)
	{
		Marker* marker = [self createMarkerForNode:i imageHierarchy:hierarchy andImageContour:contours];
		if (marker != nil)
		{
			NSString* markerKey = [self getCodeKey:marker];
			Action* actionForCode = [self.settings.experience actionForCode:markerKey];
			if(self.settings.validCodes.count == 0 || [self.settings.validCodes containsObject:markerKey])
			{
				cv::RotatedRect rBoundingRect = cv::minAreaRect(contours.at(i));
				double markerSize = sqrt(pow(rBoundingRect.size.width, 2) + pow(rBoundingRect.size.height,2));
				double minimumSize = [[actionForCode nsMinimumSize] doubleValue];
				if (diagonalSize == 0 || markerSize/diagonalSize > minimumSize)
				{
					[markers addObject: marker];
					
					if(self.settings.displayOutline > 0 || self.settings.displayText == 1)
					{
						[self drawMarker:markerKey atIndex:i onOverlay:buffers.overlay withContours:contours andHierarchy:hierarchy];
					}
				}
			}
		}
	}
	
	//NSLog(@"Skipped contours: %d/%lu",skippedContours,contours.size());
	return markers;
}

-(NSString*)getCodeKey:(Marker*)marker
{
	NSMutableString* codeStr = [[NSMutableString alloc] init];
	
	for (int i = 0; i < marker.regions.count; i++)
	{
		if(i != 0)
		{
			[codeStr appendString:@":"];
		}
		[codeStr appendFormat:@"%ld", (long)[marker.regions objectAtIndex:i].value];
	}
	
	return codeStr;
}

-(Marker*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy andImageContour:(std::vector<std::vector<cv::Point> >&)contours
{
	NSMutableArray* regions = nil;
	
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
		else
		{
			return nil;
		}
	}

	if (regions != nil)
	{
		[self sortRegions:regions];
		Marker* marker = [[Marker alloc] initWithIndex:nodeIndex regions:regions];
		if([self isValidRegionList:marker])
		{
			return marker;
		}
	}
	return nil;
}

-(void)sortRegions:(NSMutableArray*) regions
{
	[regions sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]]];
}

-(BOOL)isValidRegionList:(Marker*) marker
{
	if (marker == nil || marker.regions == nil)
	{
		// No Code
		return false;
	}
	else if (marker.regions.count < self.settings.minRegions)
	{
		// Too Short
		return false;
	}
	else if (marker.regions.count > self.settings.maxRegions)
	{
		// Too long
		return false;
	}
	
	int numberOfEmptyRegions = 0;
	for (MarkerRegion* region in marker.regions)
	{
		//check if leaves are using in accepted range.
		if (region.value > self.settings.maxRegionValue)
		{
			return false; // value is too Big
		}
		else if (region.value==0 && ++numberOfEmptyRegions>self.settings.maxEmptyRegions)
		{
			return false; // too many empty regions
		}
	}
	
	return [self hasValidChecksum:marker];
}

-(BOOL)hasValidChecksum:(Marker*) marker
{
	if (self.settings.checksum <= 1)
	{
		return true;
	}
	int numberOfLeaves = 0;
	for (MarkerRegion* region in marker.regions)
	{
		numberOfLeaves += region.value;
	}
	return (numberOfLeaves % self.settings.checksum) == 0;
}

-(MarkerRegion*)createRegionForNode:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0 && !(self.settings.ignoreEmptyRegions || self.settings.maxEmptyRegions>0))
	{
		// There are no dots, and empty regions are not allowed.
		return nil;
	}
	
	// Count all the dots and check if they are leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidLeaf:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get the next dot index:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			
			if (dotCount > self.settings.maxRegionValue)
			{
				// Too many dots
				return nil;
			}
		}
		else
		{
			// Not a leaf
			return nil;
		}
	}
	
	return [[MarkerRegion alloc] initWithIndex:regionIndex value:dotCount];
}

-(bool)isValidLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] < 0;
}

-(void)drawMarker:(NSString*)marker atIndex:(int)index onOverlay:(cv::Mat) overlay withContours:(std::vector<std::vector<cv::Point>>)contours andHierarchy:(std::vector<cv::Vec4i>)hierarchy
{
	//color to draw contours
	cv::Scalar markerColor = cv::Scalar(0, 255, 255, 255);
	cv::Scalar regionColor = cv::Scalar(0, 128, 255, 255);
	cv::Scalar outlineColor = cv::Scalar(0, 0, 0, 255);
	
	if(self.settings.displayOutline > 0)
	{
		cv::Vec4i nodes = hierarchy.at(index);
		int currentRegionIndex= nodes[CHILD_NODE_INDEX];
		// Loop through the regions, verifing the value of each:
		if(self.settings.displayOutline == 2)
		{
			while (currentRegionIndex >= 0)
			{
				cv::drawContours(overlay, contours, currentRegionIndex, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
				cv::drawContours(overlay, contours, currentRegionIndex, regionColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
				
				// Get next region:
				nodes = hierarchy.at(currentRegionIndex);
				currentRegionIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
		}
		
		cv::drawContours(overlay, contours, index, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
		cv::drawContours(overlay, contours, index, markerColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
	}
	
	// draw code (and action name):
	if(self.settings.displayText == 1)
	{
		cv::Rect markerBounds = boundingRect(contours[index]);
		markerBounds.x = markerBounds.x;
		markerBounds.y = markerBounds.y;
		
		NSString * textToDraw = marker;
		Action * action = [self.settings.experience actionForCode:marker];
		if (action != nil && action.name != nil) {
			textToDraw = [NSString stringWithFormat:@"%@ (%@)", marker, action.name];
		}
		
		cv::putText(overlay, textToDraw.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(overlay, textToDraw.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
	}
}

@end
