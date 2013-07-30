//
//  MarkerConstraint.h
//  aestheticodes
//
//  Created by horizon on 30/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DtouchMarker.h"

@interface MarkerConstraint : NSObject
@property int minBranches;
@property int maxBranches;
@property int emptyBranches;
@property int maxLeaves;
@property int validationBranches;
@property int validationBranchLeaves;
@property int checksumModulo;
@property int markerOccurence;

-(bool)isValidDtouchMarker:(DtouchMarker*)marker;

@end
