//
//  MarkerSettings.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MarkerSettings : NSObject
@property NSArray* modes;
@property NSMutableDictionary* markers;
@property int minRegions;
@property int maxRegions;
@property int maxEmptyRegions;
@property int maxRegionValue;
@property int validationRegions;
@property int validationRegionValue;
@property int checksumModulo;
@property bool editable;
@property bool addMarkers;
@property bool changed;
@property NSString* updateURL;

+ (MarkerSettings*)settings;

-(void)load:(NSDictionary*) data;
-(bool)isValid:(NSArray*) code;
-(bool)isKeyValid:(NSString*) codeKey;
-(NSDictionary*)toDictionary;
-(void)setIntValue:(long) value key:(NSString*) key;
@end
