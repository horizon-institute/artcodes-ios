//
//  TemporalMarkerDetector.m
//  aestheticodes
//
//  Created by horizon on 05/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "TemporalMarkers.h"
#import "DtouchMarker.h"

@interface MarkerTemporalOccurence : NSObject
@property DtouchMarker *dtouchMarker;
@property int occurence;
@end

@implementation MarkerTemporalOccurence
@synthesize dtouchMarker;
@synthesize occurence;
@end


@interface TemporalMarkers ()
@property NSMutableDictionary *markerOccurences;
@property NSDate *startTime;
@property NSDate *endTime;

-(void)setupTime;
-(bool)isTimeInCurrentInterval:(NSDate*)markerTime;
@end

@implementation TemporalMarkers

@synthesize markerOccurences;
@synthesize startTime;
@synthesize endTime;

const NSTimeInterval MARKER_DETECTION_DURATION = 2;

-(id)init{
    self = [super init];
    if (self)
    {
        markerOccurences = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)integrateMarkers:(NSDictionary*)markers{
    //if there are markers in the list.
    if (markers.count > 0){
        //check if this is the first marker detected in particular duration.
        if (markerOccurences.count == 0){
            //initialize time
            [self setupTime];
        }
        
        //check if marker is within start & end time.
        NSDate *timeNow = [NSDate date];
        if ([self isTimeInCurrentInterval:timeNow]){
            for (NSString* markerCode in markers){
                DtouchMarker* dtouchMarker = [markers objectForKey:markerCode];
                int occurence = dtouchMarker.getNodeIndexes.count;
                //increase occurence if this marker is already in the list.
                MarkerTemporalOccurence *existingOccurence = [markerOccurences objectForKey:markerCode];
                if (existingOccurence != nil){
                    existingOccurence.occurence = existingOccurence.occurence + occurence;
                }else
                {
                    //new marker has been detected.
                    MarkerTemporalOccurence *newOccurence = [[MarkerTemporalOccurence alloc] init];
                    newOccurence.dtouchMarker = [markers objectForKey:markerCode];
                    newOccurence.occurence = occurence;
                    [markerOccurences setObject:newOccurence forKey:dtouchMarker.codeKey];
                }
            }
        }
    }
}

-(bool)isMarkerDetectionTimeUp{
    NSDate *timeNow = [NSDate date];
    if ([timeNow compare:endTime] == NSOrderedSame || ([timeNow compare:endTime] == NSOrderedDescending)){
        return true;
    }
    return false;
}

//initialize start and end duration of current detection interval.
-(void)setupTime{
    startTime = [NSDate date];
    endTime = [startTime dateByAddingTimeInterval:MARKER_DETECTION_DURATION];
}

-(bool)isTimeInCurrentInterval:(NSDate*)markerTime{
    //if input marker is with in start & end time.
    if (([markerTime compare:startTime] == NSOrderedSame || ([markerTime compare:startTime] == NSOrderedDescending)) &&
        (([markerTime compare:endTime] == NSOrderedSame) || ([markerTime compare:endTime] == NSOrderedAscending))){
        return true;
    }
    return false;
}

-(DtouchMarker*)guessMarker{
    DtouchMarker* marker;
    int maxOccurence = 0;
    for (NSString* markerCode in markerOccurences){
        MarkerTemporalOccurence *temporalMarker = [markerOccurences objectForKey:markerCode];
        if (temporalMarker.occurence > maxOccurence){
            marker = temporalMarker.dtouchMarker;
            maxOccurence = temporalMarker.occurence;
        }
    }
    return marker;
}

-(void)resetTemporalMarker{
    [markerOccurences removeAllObjects];
}

-(float)getIntegrationPercent{
    float percent = 0;
    NSDate *timeNow = [NSDate date];
    
    if (markerOccurences.count == 0){
        percent = 0;
    }
    else if ([self isMarkerDetectionTimeUp]){
        percent = 1.0;
    }
    else if ([self isTimeInCurrentInterval:timeNow])
    {
        //difference start time and current time. The result would be negative as current time is greater so
        // make it positive by multiplying by -1.
        NSTimeInterval timePassed = [timeNow timeIntervalSinceDate:startTime];
        //difference start time and end time.
        NSTimeInterval totalTime = [endTime timeIntervalSinceDate:startTime];
        //percentage.
        percent = timePassed/totalTime;
    }
    return percent;
}

-(bool)hasIntegrationStarted{
    if (markerOccurences.count == 0)
        return true;
    else
        return false;
}

@end
