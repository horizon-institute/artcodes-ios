//
//  TemporalMarkerDetector.h
//  aestheticodes
//
//  Created by horizon on 05/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DtouchMarker.h"

@interface TemporalMarkers : NSObject
-(void)integrateMarkers:(NSDictionary*)markers;
-(void)resetTemporalMarker;
-(bool)isMarkerDetectionTimeUp;
-(DtouchMarker*)guessMarker;
-(float)getIntegrationPercent;
-(bool)hasIntegrationStarted;
@end
