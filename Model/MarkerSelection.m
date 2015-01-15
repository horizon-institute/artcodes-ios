/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
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
@property (nonatomic, retain) NSDate *lastUpdate;
@property (nonatomic, retain) NSDate *last;
@property (nonatomic) NSTimeInterval progress;

@end

@implementation MarkerSelection

@synthesize occurences;
@synthesize lastUpdate;
@synthesize last;
@synthesize progress;

const NSTimeInterval MARKER_DETECTION_DURATION = 0.5;
const int MARKER_OCCURENCES = 5;

-(id)init{
    self = [super init];
    if (self)
    {
        occurences = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)addMarkers:(NSDictionary*)markers
{
    //if there are markers in the list.
    NSDate* now = [NSDate date];
	if (markers.count > 0)
	{
        //check if this is the first marker detected in particular duration.
        if (occurences.count == 0)
		{
			progress = 0;
        }
		else
		{
			progress += [now timeIntervalSinceDate:last];
		}
        
        //check if marker is within start & end time.
		lastUpdate = now;
		
		for (NSString* markerCode in markers)
		{
			MarkerCode* marker = [markers objectForKey:markerCode];
			long occurence = marker.nodeIndexes.count;
			//increase occurence if this marker is already in the list.
			MarkerCode *existingMarker = [occurences objectForKey:markerCode];
			if (existingMarker != nil)
			{
				existingMarker.occurence = existingMarker.occurence + occurence;
			}
			else
			{
				//new marker has been detected.
				marker.occurence = occurence;
				[marker.nodeIndexes removeAllObjects];
				[occurences setObject:marker forKey:marker.codeKey];
			}
		}
	}
	
	last = now;
}

-(bool)hasTimedOut
{
	return [self hasTimedOut:last];
}

-(bool)hasTimedOut:(NSDate*)time
{
	return [time timeIntervalSinceDate:lastUpdate] > (4 * MARKER_DETECTION_DURATION);
}

-(MarkerCode*)getSelected
{
    MarkerCode* selected;
    for (NSString* markerCode in occurences)
	{
        MarkerCode* marker = [occurences objectForKey:markerCode];
        if (selected == nil || marker.occurence > selected.occurence)
		{
			selected = marker;
        }
    }
    return selected;
}

-(void)reset
{
	progress = 0;
    [occurences removeAllObjects];
}

-(float)getTimeOutProgress
{
	NSTimeInterval timeout = [last timeIntervalSinceDate:lastUpdate];
	if(timeout > MARKER_DETECTION_DURATION)
	{
		return (timeout - MARKER_DETECTION_DURATION) / MARKER_DETECTION_DURATION;
	}
	return 0;
}

-(float)getProgress
{
    if (occurences.count == 0)
	{
        return 0;
    }
    else if ([self hasTimedOut])
	{
        return 0;
    }
	
    return progress / MARKER_DETECTION_DURATION;
}

-(bool)hasFinished
{
    return progress > MARKER_DETECTION_DURATION;
}

-(bool)hasStarted
{
	return occurences.count > 0;
}

@end