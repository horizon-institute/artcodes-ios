//
//  TemporalMarkerDetector.h
//  aestheticodes
//
//  Created by horizon on 05/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MarkerCode.h"

@interface MarkerSelection : NSObject
-(void)addMarkers:(NSDictionary*)markers;
-(void)reset;
-(bool)hasStarted;
-(bool)hasFinished;
-(bool)hasTimedOut;
-(MarkerCode*)getSelected;
-(float)getProgress;
-(float)getTimeOutProgress;

@end