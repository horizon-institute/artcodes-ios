//
//  ACMarkerDb.h
//  aestheticodes
//
//  Created by horizon on 30/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DtouchMarker.h"

@interface ACMarkerDB : NSObject

+(id)getSharedInstance;
-(NSString*)getUrlStringForMarker:(DtouchMarker*)marker;

@end

