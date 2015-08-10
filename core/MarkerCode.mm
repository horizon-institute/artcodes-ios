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
#import "MarkerCode.h"
#import "ExperienceManager.h"

NSString *const REGION_VALUE = @"value";
NSString *const REGION_INDEX = @"index";

@implementation ACXMarkerDetails
-(ACXMarkerDetails*)initWithDetails:(ACXMarkerDetails*)details
{
	self = [super init];
	self.regions = details.regions;
	self.embeddedChecksum = details.embeddedChecksum;
	self.markerIndex = details.markerIndex;
	return self;
}
@end

@interface MarkerCode()
@property (weak) id<ACXMarkerDrawer> markerDrawer;
@property NSArray* code;
@end

@implementation MarkerCode

@synthesize code;
@synthesize codeKey;
@synthesize occurrence;
@synthesize regionCount;
@synthesize emptyRegionCount;

-(MarkerCode*)initWithCodeKey:(NSString*)codeKeyInput andDetails:(ACXMarkerDetails*)details  andDrawer:(id<ACXMarkerDrawer>)drawer
{
	self = [super init];
	
	self.codeKey = codeKeyInput;
	self.markerDetails = [[NSMutableArray alloc] initWithObjects: details, nil];
	self.markerDrawer = drawer;
	
	self.code = [details.regions valueForKey:REGION_VALUE];
	self.occurrence = 1;
	
	return self;
}

-(void)addMarkerInstance:(MarkerCode*)marker
{
	if ([marker.codeKey isEqualToString:self.codeKey])
	{
		[self.markerDetails addObjectsFromArray:marker.markerDetails];
		self.occurrence += marker.occurrence;
	}
}

-(int)regionCount
{
	return (int)[self.code count];
}

-(int)emptyRegionCount
{
	int numberOfEmptyBranches = 0;
	
	for (NSNumber* leaves in self.code){
		if ([leaves intValue] == 0)
			numberOfEmptyBranches++;
	}
	return numberOfEmptyBranches;
}

-(void)drawMarkerForImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor
{
	[self.markerDrawer drawMarker:self forImage:image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:markerColor andOutlineColor:outlineColor andRegionColor:regionColor];
}


@end
