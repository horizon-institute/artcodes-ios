//
//  TemporalMarkerDetector.m
//  aestheticodes
//
//  Created by horizon on 05/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerSelection.h"
#import "Marker.h"

@interface MarkerSelection ()
@property NSMutableDictionary *occurences;
@property NSDate *lastUpdate;
@property NSDate *last;
@property NSTimeInterval progress;

@end

@implementation MarkerSelection

@synthesize occurences;
@synthesize lastUpdate;
@synthesize last;
@synthesize progress;

const NSTimeInterval MARKER_DETECTION_DURATION = 1;

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
			Marker* marker = [markers objectForKey:markerCode];
			long occurence = marker.nodeIndexes.count;
			//increase occurence if this marker is already in the list.
			Marker *existingMarker = [occurences objectForKey:markerCode];
			if (existingMarker != nil)
			{
				existingMarker.occurence = existingMarker.occurence + occurence;
			}
			else
			{
				//new marker has been detected.
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
	return [time timeIntervalSinceDate:lastUpdate] > (2 * MARKER_DETECTION_DURATION);
}

-(Marker*)getSelected
{
    Marker* selected;
    for (NSString* markerCode in occurences)
	{
        Marker* marker = [occurences objectForKey:markerCode];
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