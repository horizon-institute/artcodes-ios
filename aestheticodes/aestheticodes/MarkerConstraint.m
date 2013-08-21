//
//  MarkerConstraint.m
//  aestheticodes
//
//  Created by horizon on 30/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerConstraint.h"

@implementation MarkerConstraint

@synthesize minBranches;
@synthesize maxBranches;
@synthesize emptyBranches;
@synthesize maxLeaves;
@synthesize validationBranches;
@synthesize validationBranchLeaves;
@synthesize checksumModulo;
@synthesize markerOccurence;

-(id)init{
    self = [super init];
    if (self){
        minBranches = 5;
        maxBranches = 5;
        emptyBranches = 0;
        maxLeaves = 6;
        validationBranches = 2;
        validationBranchLeaves = 1;
        checksumModulo = 6;
        markerOccurence = 1;
    }
    return self;
}

/*
This function checks if the code fulfils the marker constraints provided in the settings.
@return true if marker fulfils the constraint otherwise false.
*/
-(bool)isValidDtouchMarker:(DtouchMarker*)marker{
    bool valid = FALSE;
    if ([self hasValidNumberOfBranches:marker])
        if([self hasValidNumberOfEmptyBranches:marker])
            if ([self hasValidNumberOfLeaves:marker])
                if ([self hasValidationBranches:marker])
                    if ([self hasValidCheckSum:marker])
                        valid = TRUE;
    return valid;
}

/*
It checks the number of validation branches as set in the settings. The code is valid if the number of branches which contains the validation code are equal or greater than the number of validation branches mentioned in the settings.
 Returns true if the number of validation branches are >= validation branch value in the preference otherwise it returns false.
*/
-(bool)hasValidationBranches:(DtouchMarker*)marker{
    bool valid = FALSE;
    int numberOfValidationBranches = 0;
    //determine number of validation branches in the code.
    for (NSNumber *leaves in marker.code){
        if ([leaves intValue] == self.validationBranchLeaves)
            numberOfValidationBranches++;
    }
    if (numberOfValidationBranches >= self.validationBranches)
        valid = true;
    
    return valid;
}

/*
This function divides the total number of leaves in the marker by the value given in the checksum preference. Code is valid if the modulo is 0.
@return true if the number of leaves are divisible by the checksum value otherwise false.
*/

-(bool)hasValidCheckSum:(DtouchMarker*)marker{
    bool valid = FALSE;
    int numberOfLeaves = 0;
    for (NSNumber* leaves in marker.code){
        numberOfLeaves += [leaves intValue];
    }
    if (self.checksumModulo > 0){
        double checksum = numberOfLeaves % self.checksumModulo;
        if (checksum == 0)
            valid = true;
    }
    return valid;
}


-(bool)hasValidNumberOfBranches:(DtouchMarker*)marker{
    bool valid = FALSE;
    
    if ((marker.totalNumberOfBranches >= minBranches) && (marker.totalNumberOfBranches <= maxBranches))
        valid = TRUE;
    
    return valid;
}

-(bool)hasValidNumberOfEmptyBranches:(DtouchMarker*)marker{
    
    bool valid = FALSE;
    if (marker.totalNumberOfEmptyBranches == emptyBranches){
        valid = TRUE;
    }
    return valid;
}

-(bool)hasValidNumberOfLeaves:(DtouchMarker*)marker{
    bool valid = FALSE;
    for (NSNumber* leaves in marker.code){
        //check if leaves are with in accepted range.
        if ([leaves intValue] <= self.maxLeaves){
            valid = TRUE;
        }
    }
    return valid;
}

@end
