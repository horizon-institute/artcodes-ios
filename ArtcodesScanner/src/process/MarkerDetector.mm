//
//  MarkerDetector.m
//  Artcodes
//
//  Created by Kevin Glover on 20 Oct 2015.
//  Copyright © 2015 Horizon DER Institute. All rights reserved.
//

#import "MarkerDetector.h"
#import <vector>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@interface MarkerDetector()

@property DetectionSettings* settings;

@end

const static int CHILD_NODE_INDEX = 2;
const static int NEXT_SIBLING_NODE_INDEX = 0;
const static int REGION_INVALID = -1;
const static int REGION_EMPTY = 0;

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

-(cv::Mat) process:(cv::Mat) image withOverlay:(cv::Mat) overlay
{
	std::vector<std::vector<cv::Point> > contours;
	std::vector<cv::Vec4i> hierarchy;
	cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	// This autoreleasepool prevents memory allocated in [self findMarkers] from leaking.
	@autoreleasepool{
		//detect markers
		NSArray* markers = [self findMarkers:hierarchy andImageContour:contours andOverlay:overlay];
		
		self.settings.detected = markers.count > 0;
		if(self.settings.handler != nil)
		{
			self.settings.handler(markers);
		}
	}

	return image;
}

-(NSArray*)findMarkers:(std::vector<cv::Vec4i>)hierarchy andImageContour:(std::vector<std::vector<cv::Point> >)contours andOverlay:(cv::Mat) overlay
{
	/*! Detected markers */
	NSMutableArray* markers = [[NSMutableArray alloc] init];
	//int skippedContours = 0;
	
	//NSLog(@"Contours %lu", contours.size());
	for (int i = 0; i < contours.size(); i++)
	{
		//if (contours[i].size() < self.cameraSettings.minimumContourSize)
		//{
		//	++skippedContours;
		//	continue;
		//}
		
		NSArray* markerCode = [self createMarkerForNode:i imageHierarchy:hierarchy];
		if (markerCode != nil)
		{
			NSString* markerKey = [self getCodeKey:markerCode];
			if([self.settings.validCodes containsObject:markerKey])
			{
				[markers addObject: markerKey];
				
				[self drawMarker:markerKey atIndex:i onOverlay:overlay withContours:contours andHierarchy:hierarchy];
			}
		}
	}
	
	//NSLog(@"Skipped contours: %d/%lu",skippedContours,contours.size());
	return markers;
}

-(NSString*)getCodeKey:(NSArray*)code
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

-(NSArray*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	int currentRegionIndex = imageHierarchy.at(nodeIndex)[CHILD_NODE_INDEX];
	if (currentRegionIndex < 0)
	{
		//NSLog(@"No regions");
		return nil; // There are no regions.
	}
	
	int numOfRegions = 0;
	int numOfEmptyRegions = 0;
	NSMutableArray* markerCode = nil;
	NSNumber* embeddedChecksumValue = nil;
	
	// Loop through the regions, verifing the value of each:
	for (; currentRegionIndex >= 0; currentRegionIndex = imageHierarchy.at(currentRegionIndex)[NEXT_SIBLING_NODE_INDEX])
	{
		int regionValue = [self getRegionValueForRegionAtIndex:currentRegionIndex inImageHierarchy:imageHierarchy];
		if (regionValue == REGION_EMPTY)
		{
			//NSLog(@"Empty region: %@",markerCode);
			return nil;
		}
		
		if (regionValue == REGION_INVALID)
		{
			// Not a normal region, so look for embedded checksum:
			if (self.settings.embeddedChecksum && embeddedChecksumValue == nil) // if we've not found it yet:
			{
				embeddedChecksumValue = [self getEmbeddedChecksumValueForRegionAtIndex:currentRegionIndex inImageHierarchy:imageHierarchy];
				if (embeddedChecksumValue != nil)
				{
					continue; // this is a checksum region, so continue looking for regions
				}
			}
			
			//NSLog(@"Too many levels: %@",markerCode);
			return nil; // Too many levels.
		}
		
		if(++numOfRegions > self.settings.maxRegions)
		{
			//NSLog(@"Too many regions: %@",markerCode);
			return nil; // Too many regions.
		}
		
		// Add region value to code:
		if (markerCode == nil)
		{
			markerCode = [[NSMutableArray alloc] initWithObjects:@(regionValue), nil];
		}
		else
		{
			[markerCode addObject:@(regionValue)];
		}
	}
	
	// Marker should have at least one non-empty branch. If all branches are empty then return false.
	if ((numOfRegions - numOfEmptyRegions) < 1)
	{
		//NSLog(@"Empty regions: %@",markerCode);
		return nil;
	}
	
	// sort the code (the order may effect embedded checksum)
	NSArray* sortedMarkerCode = [markerCode sortedArrayUsingSelector: @selector(compare:)];
	if ([self.settings isValid:sortedMarkerCode withEmbeddedChecksum:embeddedChecksumValue])
	{
		return sortedMarkerCode;
	}
	return nil;
}

-(int)getRegionValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return REGION_EMPTY; // There are no dots.
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
				return REGION_INVALID; // Too many dots.
			}
		}
		else
		{
			return REGION_INVALID; // Dot is not a leaf.
		}
	}
	
	return dotCount;
}

-(bool)isValidLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] < 0;
}

-(NSNumber*)getEmbeddedChecksumValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return nil; // There are no dots.
	}
	
	// Count all the dots and check if they are double-leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidDoubleLeaf:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get the next dot index:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
		}
		else
		{
			return nil; // Wrong number of levels.
		}
	}
	
	return @(dotCount);
}

-(bool)isValidDoubleLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] >= 0 && // has a child node, and
		imageHierarchy.at(nodes[CHILD_NODE_INDEX])[NEXT_SIBLING_NODE_INDEX] < 0 && //the child has no siblings, and
		[self isValidLeaf:nodes[CHILD_NODE_INDEX] inImageHierarchy:imageHierarchy];// the child is a leaf
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
	
	// draw code:
	if(self.settings.displayText == 1)
	{
		cv::Rect markerBounds = boundingRect(contours[index]);
		markerBounds.x = markerBounds.x;
		markerBounds.y = markerBounds.y;
		
		cv::putText(overlay, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(overlay, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
	}
}

@end
