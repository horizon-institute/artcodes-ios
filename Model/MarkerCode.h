//
//  DtouchMarker.h
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface MarkerCode : NSObject
@property NSArray* code;
@property (readonly) NSString* codeKey;
@property (readonly) int emptyRegionCount;
@property (readonly) int regionCount;
@property long occurence;
@property (readonly) NSMutableArray* nodeIndexes;

- (id)initWithCode:(NSArray*)codeArray andKey:(NSString*)key;
+(NSString*)getCodeKey:(NSArray*)code;

@end