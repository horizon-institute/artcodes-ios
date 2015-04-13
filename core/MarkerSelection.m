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
#import "MarkerSelection.h"
#import "MarkerCode.h"

@interface MarkerSelection ()
@property (nonatomic, retain) NSMutableDictionary *occurences;
@property int required;

@end

@implementation MarkerSelection

-(id)init{
    self = [super init];
    if (self)
    {
		self.occurences = [[NSMutableDictionary alloc] init];
        self.required = 5;
    }
    return self;
}

-(NSString*)addMarkers:(NSDictionary*)markers
{
	NSMutableArray* updated = [[NSMutableArray alloc] init];
	//final Collection<String> updated = new HashSet<>();
	for (NSString* markerCode in markers)
	{
		MarkerCode* marker = [markers objectForKey:markerCode];
		long occurence = marker.nodeIndexes.count;
		//increase occurence if this marker is already in the list.
		MarkerCode *existingMarker = [self.occurences objectForKey:markerCode];
		if (existingMarker != nil)
		{
			existingMarker.occurence = MIN(self.required * 5, existingMarker.occurence + occurence);
		}
		else
		{
			//new marker has been detected.
			marker.occurence = occurence;
			[marker.nodeIndexes removeAllObjects];
			//[self.occurences setObject:marker forKey:markerCode];
			[self.occurences setObject:marker forKey:markerCode];
		}
		
		[updated addObject:markerCode];
	}

	MarkerCode* likely = nil;
	for(NSString* markerCode in self.occurences)
	{
		MarkerCode* marker = [self.occurences objectForKey:markerCode];
		if(![updated containsObject:markerCode])
		{
			marker.occurence = MAX(0, marker.occurence - 1);
		}
		
		//NSLog(@"%@ occurs %ld", markerCode, marker.occurence);
		if (marker.occurence > self.required && (likely == nil || marker.occurence > likely.occurence))
		{
			likely = marker;
		}
	}
	
	if (likely == nil)
	{
		return nil;
	}
	else
	{
		return likely.codeKey;
	}
}

-(void)reset
{
	NSLog(@"Reset Selection");
    [self.occurences removeAllObjects];
}
@end
