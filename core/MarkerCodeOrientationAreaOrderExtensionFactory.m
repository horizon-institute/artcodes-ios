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

#import "MarkerCodeOrientationAreaOrderExtensionFactory.h"

@implementation MarkerCodeOrientationAreaOrderExtensionFactory

-(void)sortCode:(ACXMarkerDetails*)details;
{
	// sort by left to right
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[@"x"] doubleValue] < [b[@"x"] doubleValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
	
	// label
	int count = 0;
	for (NSMutableDictionary *region in details.regions)
	{
		region[REGION_LABEL] = [NSString stringWithFormat:@"%c", (char)(65+count++)];
	}
	
	// sort by area
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[REGION_AREA] doubleValue] < [b[REGION_AREA] doubleValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
}

@end
