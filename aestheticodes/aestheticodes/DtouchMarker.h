//
//  DtouchMarker.h
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DtouchMarker : NSObject
@property int nodeIndex;
@property int occurence;
@property NSArray* code;
@property (readonly) NSString* codeKey;
@end
