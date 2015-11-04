/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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
#import "JSONModel.h"
#import "Marker.h"
#import <Foundation/Foundation.h>

@class MarkerCodeFactory;

@interface Experience : JSONModel
@property (nonatomic, retain) NSString* id;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* icon;
@property (nonatomic, retain) NSString* image;
@property (nonatomic, retain) NSString* description;
@property (nonatomic, retain) NSString* callback;
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
@property (nonatomic) bool embeddedChecksum;
@property (nonatomic) bool relaxedEmbeddedChecksumIgnoreMultipleHollowSegments;
@property (nonatomic) bool relaxedEmbeddedChecksumIgnoreNonHollowDots;
@property (nonatomic) bool ignoreEmptyRegions;

@property (nonatomic) bool comingSoon;

@property (nonatomic, retain) NSString* openMode;

@property (nonatomic) NSArray* greyscaleOptions;
@property (nonatomic) bool invertGreyscale;
@property (nonatomic) double hueShift;
@property (nonatomic) NSArray<NSString*>* imageProcessingComponents;

@property (nonatomic, retain) NSString* startUpURL;

@property (nonatomic, retain) NSString* thresholdBehaviour;

@property (nonatomic, retain) NSDictionary* hintText;

-(bool)isValid:(NSArray*)code withEmbeddedChecksum:(NSNumber*)embeddedChecksum reason:(NSMutableString*)reason;
-(bool)isKeyValid:(NSString*)codeKey reason:(NSMutableString*)reason;
-(Marker*)getMarker:(NSString*) codeKey;
-(NSString*)getNextUnusedMarker;

-(MarkerCodeFactory*)getMarkerCodeFactory;

-(bool)hasCodeBeginningWith:(NSString*)codeSubstring;

-(bool)isValidExceptChecksum:(NSArray *)code reason:(NSMutableString *)reason;

-(NSSet<NSString*>*)acceptableMarkerCodes;

@end
