//
//  DtouchMarker.h
//  aestheticodes
//
//  Created by horizon on 18/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DtouchMarker : NSObject
@property NSArray* code;
@property (readonly) NSString* codeKey;
@property (readonly) int totalNumberOfEmptyBranches;
@property (readonly) int totalNumberOfBranches;

-(void)addNodeIndex:(int) nodeIndex;
-(void)removeNodeIndex:(int) nodeIndex;
-(NSArray*)getNodeIndexes;
@end
