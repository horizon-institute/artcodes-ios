//
//  Experience.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "JSONModel.h"
#import "MarkerAction.h"
#import <Foundation/Foundation.h>

@interface Experience : JSONModel
@property (nonatomic, retain) NSString* id;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* icon;
@property (nonatomic, retain) NSArray* modes;
@property (nonatomic, retain) NSMutableArray<MarkerAction>* markers;
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
@property (nonatomic, retain) NSString* lastUpdate;

@property (nonatomic) int minimumContourSize;
@property (nonatomic) int maximumContoursPerFrame;
@property (nonatomic, retain) NSString* thresholdBehaviour;

-(bool)isValid:(NSArray*) code;
-(bool)isKeyValid:(NSString*) codeKey;
-(void)setIntValue:(long) value key:(NSString*) key;
-(MarkerAction*)getMarker:(NSString*) codeKey;
@end