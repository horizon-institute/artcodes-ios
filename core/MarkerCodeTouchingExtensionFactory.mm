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
#import "MarkerCodeTouchingExtensionFactory.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "Experience.h"

#define LINE_WIDTH 10

NSString *const REGION_TOUCHING = @"touching";


@interface ACXTouchingMarkerDetails : ACXMarkerDetails
@property cv::vector<cv::vector<cv::vector<cv::Point> > * > allOverlapContours;
-(ACXTouchingMarkerDetails*)initWithAllOverlapContours:(cv::vector<cv::vector<cv::vector<cv::Point> > * >)allOverlapContours andExistingDeatils:(ACXMarkerDetails*)details;
-(int)touchCount;
@end
@implementation ACXTouchingMarkerDetails
-(ACXTouchingMarkerDetails*)initWithAllOverlapContours:(cv::vector<cv::vector<cv::vector<cv::Point> > * >)allOverlapContours andExistingDeatils:(ACXMarkerDetails*)details
{
	self = [super initWithDetails:details];
	self.allOverlapContours = allOverlapContours;
	return self;
}
-(int)touchCount
{
	int count = 0;
	for (NSDictionary *regionDetails in self.regions)
	{
		count += (unsigned long) [regionDetails[REGION_TOUCHING] count];
	}
	return count;
}
@end

@interface MarkerCodeTouchingExtensionFactory ()
@property bool combinedEmbeddedChecksum;
@property bool withChecksum;
@end

@implementation MarkerCodeTouchingExtensionFactory

-(MarkerCodeTouchingExtensionFactory*)initWithChecksum:(bool)withChecksum orCombinedEmbeddedChecksum:(bool)combinedEmbeddedChecksum
{
	self = [super init];
	self.combinedEmbeddedChecksum = combinedEmbeddedChecksum;
	self.withChecksum = withChecksum;
	return self;
}

-(NSString*)getCodeFor:(ACXMarkerDetails*)details
{
	int count = 0;
	NSMutableString* builder = [NSMutableString stringWithCapacity:[details.regions count]*4-1];
	for (NSDictionary *regionDetails in details.regions)
	{
		if ([builder length]!=0)
		{
			[builder appendString:@":"];
		}
		[builder appendFormat:@"%@-%lu", regionDetails[REGION_VALUE], (unsigned long)[regionDetails[REGION_TOUCHING] count]];
		count += (unsigned long)[regionDetails[REGION_TOUCHING] count];
	}
	[builder appendFormat:@" (T: %d)", count];
	return builder;
}

-(ACXMarkerDetails*)parseRegionsAt:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionStatus*)error
{
	ACXMarkerDetails *details = [super parseRegionsAt:nodeIndex withContours:contours andHierarchy:hierarchy withExperience:experience error:error];
	
	if (details != nil)
	{
		cv::Rect markerBoundingBox = cv::boundingRect(contours.at(details.markerIndex));
		cv::Size size = markerBoundingBox.size();
		cv::vector<cv::vector<cv::vector<cv::Point> > * > allOverlapContours;
		
		bool drawnMat[details.regions.count];
		cv::Mat ** mats = new cv::Mat*[details.regions.count];
		
		// create bounding boxes for all regions
		cv::Rect * boundingBoxes = new cv::Rect[details.regions.count];
		for (int i=0; i<details.regions.count; ++i)
		{
			NSMutableDictionary *regionDetails = details.regions[i];
			boundingBoxes[i] = cv::boundingRect(contours.at([regionDetails[REGION_INDEX] intValue]));
			drawnMat[i] = false;
			regionDetails[REGION_TOUCHING] = [[NSMutableArray alloc] init];
		}
		
		cv::Mat temp(markerBoundingBox.size(), CV_8UC1);
		for (int i=0; i<details.regions.count; ++i)
		{
			for (int j=i+1; j<details.regions.count; ++j)
			{
				if (!drawnMat[i])
				{
					mats[i] = new cv::Mat(size, CV_8UC1, cv::Scalar(0));
					NSMutableDictionary *regionDetails = details.regions[i];
					cv::drawContours(*mats[i], contours, [regionDetails[REGION_INDEX] intValue], cv::Scalar(255), LINE_WIDTH, 8, hierarchy, 0, cv::Point(-markerBoundingBox.tl().x, -markerBoundingBox.tl().y));
					drawnMat[i] = true;
				}
				if (!drawnMat[j])
				{
					mats[j] = new cv::Mat(size, CV_8UC1, cv::Scalar(0));
					NSMutableDictionary *regionDetails = details.regions[j];
					cv::drawContours(*mats[j], contours, [regionDetails[REGION_INDEX] intValue], cv::Scalar(255), LINE_WIDTH, 8, hierarchy, 0, cv::Point(-markerBoundingBox.tl().x, -markerBoundingBox.tl().y));
					drawnMat[j] = true;
				}
				cv::bitwise_and(*mats[i], *mats[j], temp);
				int count = cv::countNonZero(temp);
				if (count>0)
				{
					[details.regions[i][REGION_TOUCHING] addObject:@(j)];
					[details.regions[j][REGION_TOUCHING] addObject:@(i)];
				}
				
				
				cv::vector<cv::vector<cv::Point> > * overlapContours = new cv::vector<cv::vector<cv::Point> >();
				cv::findContours(temp, *overlapContours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
				allOverlapContours.push_back(overlapContours);
			}
			if (drawnMat[i]) {
				delete mats[i];
			}
		}
		
		delete[] mats;
		delete[] boundingBoxes;
		
		details = [[ACXTouchingMarkerDetails alloc] initWithAllOverlapContours:allOverlapContours andExistingDeatils:details];
	}
	
	return details;
}

-(void)sortCode:(ACXMarkerDetails*)details;
{
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		if ([a[REGION_VALUE] intValue] < [b[REGION_VALUE] intValue])
		{
			return NSOrderedAscending;
		}
		else if ([a[REGION_VALUE] intValue] > [b[REGION_VALUE] intValue])
		{
			return NSOrderedDescending;
		}
		else
		{
			if ([a[REGION_TOUCHING] count] < [b[REGION_TOUCHING] count])
			{
				return NSOrderedAscending;
			}
			else
			{
				return NSOrderedDescending;
			}
		}
	}];
}

-(bool)validate:(ACXMarkerDetails*)details withExperience:(Experience*)experience error:(DetectionStatus*)error
{
	if (self.combinedEmbeddedChecksum)
	{
		NSMutableString *strError = [[NSMutableString alloc] init];
		NSArray *code = [details.regions valueForKey:REGION_VALUE];
		bool result = false;
		if (details.embeddedChecksum==nil)
		{
			result = false;
		}
		else
		{
			int expectedChecksum = 0;
			for (int i=0; i<[details.regions count]; ++i)
			{
				NSDictionary* region = details.regions[i];
				expectedChecksum += (i+1) * [region[REGION_VALUE] intValue] + [region[REGION_TOUCHING] count];
			}
			expectedChecksum = expectedChecksum%7;
			if (expectedChecksum==0)
			{
				expectedChecksum = 7;
			}
			
			if (expectedChecksum==[details.embeddedChecksum intValue])
			{
				result = [experience isValidExceptChecksum:code reason:strError];
			}
			else
			{
				error[0] = checksum;
			}
		}
		
		if ([strError containsString:@"Too many dots"])
		{
			error[0] = numberOfDots;
		}
		else if ([strError containsString:@"checksum"])
		{
			error[0] = checksum;
		}
		else if ([strError containsString:@"Validation regions"])
		{
			error[0] = validationRegions;
		}
		
		return result;
	}
	
	if ([super validate:details withExperience:experience error:error])
	{
		if (self.withChecksum)
		{
			if ([((ACXTouchingMarkerDetails*)details) touchCount] % 3 == 0 && [((ACXTouchingMarkerDetails*)details) touchCount] > 0)
			{
				return true;
			}
			else
			{
				*error = extensionSpecificError;
				return false;
			}
		}
		else
		{
			return true;
		}
	}
	else
	{
		return false;
	}
}

-(void)drawMarker:(MarkerCode*)marker forImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor
{
	for (ACXMarkerDetails *markerDetails in marker.markerDetails)
	{
		if ([markerDetails isKindOfClass:ACXTouchingMarkerDetails.class])
		{
			for (NSDictionary *region in markerDetails.regions)
			{
				int regionIndex = [region[REGION_INDEX] intValue];
				cv::drawContours(image, contours, regionIndex, cv::Scalar(0,255,255,127), LINE_WIDTH, 8, hierarchy, 0, cv::Point(0, 0));
			}
			
			cv::Rect markerBoundingBox = cv::boundingRect(contours.at(markerDetails.markerIndex));
			ACXTouchingMarkerDetails* tMarkerDetails = (ACXTouchingMarkerDetails*) markerDetails;
			for (int i=0; i<tMarkerDetails.allOverlapContours.size(); ++i)
			{
				cv::vector<cv::vector<cv::Point> > * overlapContours = tMarkerDetails.allOverlapContours.at(i);
				if (overlapContours->size() > 0)
					cv::drawContours(image, *overlapContours, -1, cv::Scalar(0,0,255,255), CV_FILLED, 8 , cv::noArray(), 0, markerBoundingBox.tl());
				delete overlapContours;
			}
			tMarkerDetails.allOverlapContours.clear();
		}
	}
}

@end
