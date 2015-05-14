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
#import "MarkerCodeFactoryAreaOrderExtension.h"

NSString *const REGION_AREA = @"area";

@implementation MarkerCodeFactoryAreaOrderExtension

-(ACXMarkerDetails*)parseRegionsAt:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error
{
	ACXMarkerDetails *details = [super parseRegionsAt:nodeIndex withContours:contours andHierarchy:hierarchy withExperience:experience error:error];
	
	if (details != nil)
	{
		// find/add areas
		for (NSMutableDictionary *regionDetails in details.regions)
		{
			// find area
			cv::vector<cv::Point> region = contours.at([regionDetails[REGION_INDEX] intValue]);
			double area = cv::contourArea(region);
			[regionDetails setObject:@(area) forKey:REGION_AREA];
		}
	}
	
	return details;
}

-(void)sortCode:(ACXMarkerDetails*)details;
{
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[REGION_AREA] doubleValue] < [b[REGION_AREA] doubleValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
}

@end
