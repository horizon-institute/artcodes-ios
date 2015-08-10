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
#import "MarkerCodeFactoryExtension.h"
#import "Experience.h"

@implementation MarkerCodeFactory

-(void)generateExtraFrameDetailsForThresholdedImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy
{}


-(MarkerCode*)createMarkerForNode:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error
{
	ACXMarkerDetails *markerDetails = [self createMarkerDetailsForNode:nodeIndex withContours:contours andHierarchy:hierarchy withExperience:experience error:error];
	if (markerDetails != nil)
	{
		*error = OK;
		return [[MarkerCode alloc] initWithCodeKey:[self getCodeFor:markerDetails] andDetails:markerDetails andDrawer:self];
	}
	else
	{
		return nil;
	}
}


-(ACXMarkerDetails*)createMarkerDetailsForNode:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error
{
	ACXMarkerDetails *markerDetails = [self parseRegionsAt:nodeIndex withContours:contours andHierarchy:hierarchy withExperience:experience error:error];
	if (markerDetails!=nil)
	{
		[self sortCode:markerDetails];
		if (![self validate:markerDetails withExperience:experience error:error])
		{
			markerDetails = nil;
		}
	}
	return markerDetails;
}

-(NSString*)getCodeFor:(ACXMarkerDetails*)details
{
	return [[details.regions valueForKey:REGION_VALUE] componentsJoinedByString:@":"];
}

//// PARSE ////

#define CHILD_NODE_INDEX		2
#define NEXT_SIBLING_NODE_INDEX	0

#define BRANCH_INVALID	-1
#define BRANCH_EMPTY	 0

-(ACXMarkerDetails*)parseRegionsAt:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error
{
	//get the first child node.
	int currentRegionIndex = hierarchy.at(nodeIndex)[CHILD_NODE_INDEX];
	//if there is a child node (region) then verify regions.
	if (currentRegionIndex < 0)
	{
		error[0] = noSubContours;
		return nil; // There are no regions.
	}
	
	int numOfRegions = 0;
	int numOfEmptyRegions = 0;
	NSMutableArray* markerCode = nil;
	
	int checksumValue = 0;
	int checksumRegionIndex = 0;
	
	// Loop through the regions, verifing the value of each:
	for (;currentRegionIndex >= 0; currentRegionIndex = hierarchy.at(currentRegionIndex)[NEXT_SIBLING_NODE_INDEX])
	{
		int regionValue = [MarkerCodeFactory getRegionValueForRegionAtIndex:currentRegionIndex inImageHierarchy:hierarchy withMaxValue:experience.maxRegionValue];
		if (regionValue == BRANCH_EMPTY)
		{
			if(++numOfEmptyRegions > experience.maxEmptyRegions)
			{
				error[0] = tooManyEmptyRegions;
				return nil; // Too many empty regions.
			}
		}
		
		if (regionValue == BRANCH_INVALID)
		{
			// look for special checksum:
			if (experience.embeddedChecksum && checksumValue <= 0) // if we've not found it yet:
			{
				checksumValue = [MarkerCodeFactory getChecksumValueForRegionAtIndex:currentRegionIndex inImageHierarchy:hierarchy];
				if (checksumValue > 0)
				{
					checksumRegionIndex = currentRegionIndex;
					continue; // this is a checksum region, so continue looking for regions
				}
			}
			error[0] = nestedRegions;
			return nil; // Too many levels.
		}
		
		if(++numOfRegions > experience.maxRegions)
		{
			error[0] = numberOfRegions;
			return nil; // Too many regions.
		}
		
		// Add region value to code:
		NSMutableDictionary *regionDetails = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@(currentRegionIndex),REGION_INDEX,@(regionValue),REGION_VALUE, nil];
		if (markerCode==nil)
		{
			markerCode = [[NSMutableArray alloc] initWithObjects:regionDetails, nil];
		}
		else
		{
			[markerCode addObject:regionDetails];
		}
	}
	
	// Marker should have at least one non-empty branch. If all branches are empty then return false.
	if ((numOfRegions - numOfEmptyRegions) < 1)
	{
		error[0] = tooManyEmptyRegions;
		return nil;
	}
	
	// Check number of regions
	if (numOfRegions < experience.minRegions || numOfRegions > experience.maxRegions)
	{
		error[0] = numberOfRegions;
		return nil;
	}
	
	if (markerCode!=nil)
	{
		ACXMarkerDetails *markerDetails = [[ACXMarkerDetails alloc] init];
		markerDetails.markerIndex = nodeIndex;
		markerDetails.embeddedChecksum = checksumValue==0?nil:@(checksumValue);
		markerDetails.embeddedChecksumRegionIndex = checksumValue==0?nil:@(checksumRegionIndex);
		markerDetails.regions = markerCode;
		return markerDetails;
	}
	return nil;
}

-(void)sortCode:(ACXMarkerDetails*)details;
{
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[REGION_VALUE] intValue] < [b[REGION_VALUE] intValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
}

-(bool)validate:(ACXMarkerDetails*)details withExperience:(Experience*)experience error:(DetectionError*)error
{
	NSMutableString *strError = [[NSMutableString alloc] init];
	NSArray *code = [details.regions valueForKey:REGION_VALUE];
	
	bool result = [experience isValid:code withEmbeddedChecksum:details.embeddedChecksum reason:strError];
	
	if ([strError rangeOfString:@"Too many dots"].location != NSNotFound)
	{
		error[0] = numberOfDots;
	}
	else if ([strError rangeOfString:@"checksum"].location != NSNotFound)
	{
		error[0] = checksum;
	}
	else if ([strError rangeOfString:@"Validation regions"].location != NSNotFound)
	{
		error[0] = validationRegions;
	}
	
	return result;
}

+(int)getRegionValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy withMaxValue:(int)regionMaxValue
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return BRANCH_EMPTY; // There are no dots.
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
			
			if (dotCount > regionMaxValue)
			{
				return dotCount; // Too many dots, stop counting.
			}
		}
		else
		{
			return BRANCH_INVALID; //fail with TOO MANY LEVELS
		}
	}
	
	return dotCount;
}

+(bool)isValidLeaf:(int)nodeIndex inImageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] < 0;
}


////////// start embedded checksum stuff //////////

+(int)newChecksumForCode:(NSArray*)code
{
	int weightedSum = 0;
	for (int i=0; i<[code count]; ++i)
	{
		weightedSum += [code[i] intValue] * (i+1);
	}
	return (weightedSum%7 == 0 ? 7 : weightedSum%7);
}

+(int)getChecksumValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return BRANCH_EMPTY; // There are no dots.
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
			return BRANCH_INVALID; // Wrong number of levels.
		}
	}
	
	return dotCount;
}

+(bool)isValidDoubleLeaf:(int)nodeIndex inImageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] >= 0 && // has a child node, and
	imageHierarchy.at(nodes[CHILD_NODE_INDEX])[NEXT_SIBLING_NODE_INDEX] < 0 && //the child has no siblings, and
	[self isValidLeaf:nodes[CHILD_NODE_INDEX] inImageHierarchy:imageHierarchy];// the child is a leaf
}

////////// end embedded checksum stuff //////////

//// PARSE END ////

-(void)drawMarker:(MarkerCode*)marker forImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor
{
	
	for (ACXMarkerDetails* markerDetail in marker.markerDetails)
	{
		// draw the regions (if the color is not transparent)
		if(regionColor[3]!=0)
		{
			for (NSNumber *currentRegionIndex in [markerDetail.regions valueForKey:REGION_INDEX])
			{
				cv::drawContours(image, contours, [currentRegionIndex intValue], outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
				cv::drawContours(image, contours, [currentRegionIndex intValue], regionColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
			}
			
			if (markerDetail.embeddedChecksumRegionIndex!=nil)
			{
				cv::Scalar xregionColor(255-regionColor[0],255-regionColor[1],255-regionColor[2],regionColor[3]);
				cv::drawContours(image, contours, [markerDetail.embeddedChecksumRegionIndex intValue], outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
				cv::drawContours(image, contours, [markerDetail.embeddedChecksumRegionIndex intValue], xregionColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
			}
		}
		
		cv::drawContours(image, contours, markerDetail.markerIndex, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
		cv::drawContours(image, contours, markerDetail.markerIndex, markerColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
	}
	
}

@end
