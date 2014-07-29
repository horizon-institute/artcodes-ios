//
//  MarkerSettings.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MarkerSettings : NSObject
@property (nonatomic, retain) NSArray* modes;
@property (nonatomic, retain) NSMutableDictionary* markers;
@property (nonatomic) int minRegions;
@property (nonatomic) int maxRegions;
@property (nonatomic) int maxEmptyRegions;
@property (nonatomic) int maxRegionValue;
@property (nonatomic) int validationRegions;
@property (nonatomic) int validationRegionValue;
@property (nonatomic) int checksumModulo;
@property (nonatomic) bool editable;
@property (nonatomic) bool addMarkers;
@property (nonatomic) bool changed;
@property (nonatomic, retain) NSString* updateURL;

@property (nonatomic) int minimumContourSize;
@property (nonatomic) int maximumContoursPerFrame;
@property (nonatomic, retain) NSString* thresholdBehaviour;

+ (MarkerSettings*)settings;

-(void)load:(NSDictionary*) data;
-(bool)isValid:(NSArray*) code;
-(bool)isKeyValid:(NSString*) codeKey;
-(NSDictionary*)toDictionary;
-(void)setIntValue:(long) value key:(NSString*) key;
@end
