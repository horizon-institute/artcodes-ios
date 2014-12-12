//
//  Experience.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "JSONModel.h"
#import "Marker.h"
#import <Foundation/Foundation.h>

@interface Experience : JSONModel
@property (nonatomic, retain) NSString* id;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* icon;
@property (nonatomic, retain) NSString* image;
@property (nonatomic, retain) NSString* description;
@property (nonatomic, retain) NSString* op;
@property (nonatomic, retain) NSMutableArray<Marker>* markers;
@property (nonatomic) int version;
@property (nonatomic) int minRegions;
@property (nonatomic) int maxRegions;
@property (nonatomic) int maxEmptyRegions;
@property (nonatomic) int maxRegionValue;
@property (nonatomic) int validationRegions;
@property (nonatomic) int validationRegionValue;
@property (nonatomic) int checksumModulo;

@property (nonatomic) int minimumContourSize;
@property (nonatomic) int maximumContoursPerFrame;
@property (nonatomic, retain) NSString* thresholdBehaviour;

-(bool)isValid:(NSArray*)code reason:(NSMutableString*)reason;
-(bool)isKeyValid:(NSString*)codeKey reason:(NSMutableString*)reason;
-(Marker*)getMarker:(NSString*) codeKey;
-(NSString*)getNextUnusedMarker;
@end
