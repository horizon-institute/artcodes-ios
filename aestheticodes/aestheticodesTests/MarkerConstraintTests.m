//
//  MarkerConstraintTests.m
//  aestheticodes
//
//  Created by horizon on 21/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerConstraintTests.h"

@implementation MarkerConstraintTests

@synthesize marker;
@synthesize constraint;

-(void)setUp
{
    [super setUp];
    marker = [[DtouchMarker alloc] init];
    constraint = [[MarkerConstraint alloc] init];
    constraint.minBranches = 5;
    constraint.maxBranches = 5;
    constraint.emptyBranches = 0;
    constraint.validationBranches = 2;
    constraint.validationBranchLeaves = 1;
    constraint.checksumModulo = 6;
    constraint.maxLeaves = 6;
    
}


- (void)tearDown
{
    [super tearDown];
}

-(void)testMarkerWithCorrectCode{
    NSMutableArray* code = [[NSMutableArray alloc] init];
    [code addObject:[[NSNumber alloc] initWithInt:1]];
    [code addObject:[[NSNumber alloc] initWithInt:1]];
    [code addObject:[[NSNumber alloc] initWithInt:3]];
    [code addObject:[[NSNumber alloc] initWithInt:3]];
    [code addObject:[[NSNumber alloc] initWithInt:4]];
    marker.code = code;
    bool valid = [constraint isValidDtouchMarker:marker];
    STAssertTrue(valid, @"Marker is valid but returned invalid");
}

-(void)testMarkerWithNoCode{
    NSMutableArray* code = [[NSMutableArray alloc] init];
    marker.code = code;
    bool valid = [constraint isValidDtouchMarker:marker];
    STAssertFalse(valid, @"Marker is invalid but returned valid");
}

-(void)testMarkerWithEmptyBranchCode{
    NSMutableArray* code = [[NSMutableArray alloc] init];
    [code addObject:[[NSNumber alloc] initWithInt:1]];
    [code addObject:[[NSNumber alloc] initWithInt:1]];
    [code addObject:[[NSNumber alloc] initWithInt:0]];
    [code addObject:[[NSNumber alloc] initWithInt:3]];
    [code addObject:[[NSNumber alloc] initWithInt:4]];
    marker.code = code;
    bool valid = [constraint isValidDtouchMarker:marker];
    STAssertFalse(valid, @"Marker is invalid as it has an empty but was returned valid");
}

@end
