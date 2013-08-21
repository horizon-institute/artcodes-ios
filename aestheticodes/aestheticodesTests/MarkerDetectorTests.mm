//
//  MarkerDetectorTests.m
//  aestheticodes
//
//  Created by horizon on 20/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerDetectorTests.h"
#import "MarkerDetector.h"

@implementation MarkerDetectorTests

@synthesize imageHierarchy;
@synthesize contours;

-(void)setUp
{
    [super setUp];
    
    // Set-up code here.
    
    //setup contours. just add one contour with point 0,0
    cv::Point point(0,0);
    
    vector<cv::Point> points;
    points.push_back(point);
    
    contours.push_back(points);
    
 }

- (void)tearDown
{
    // Tear-down code here.
    contours.clear();
    imageHierarchy.clear();
    [super tearDown];
}

- (void)testfindMarkerWithCorrectMarker
{
    
    //setup hierarchy for code 1:1:3:3:4
    //root node is 0 and it has children 1,2,3,4,5
    imageHierarchy.push_back(Vec4i(-1,-1,1,-1)); //node 0
    imageHierarchy.push_back(Vec4i(2,-1,6,0)); //node 1
    imageHierarchy.push_back(Vec4i(3,1,7,0)); //node 2.
    imageHierarchy.push_back(Vec4i(4,2,8,0)); //node 3
    imageHierarchy.push_back(Vec4i(5,3,11,0)); //node 4.
    imageHierarchy.push_back(Vec4i(-1,4,14,0)); //node 5.
    
    //node 1 children
    imageHierarchy.push_back(Vec4i(-1,-1,-1,1)); //node 6
    
    //node 2 children
    imageHierarchy.push_back(Vec4i(-1,-1,-1,2)); //node 7
    
    //node 3 children
    imageHierarchy.push_back(Vec4i(9,-1,-1,3)); //node 8
    imageHierarchy.push_back(Vec4i(10,8,-1,3)); //node 9
    imageHierarchy.push_back(Vec4i(-1,9,-1,3)); //node 10
    
    //node 4 children
    imageHierarchy.push_back(Vec4i(12,-1,-1,4)); //node 11
    imageHierarchy.push_back(Vec4i(13,11,-1,4)); //node 12
    imageHierarchy.push_back(Vec4i(-1,12,-1,4)); //node 13
    
    //node 5 children
    imageHierarchy.push_back(Vec4i(15,-1,-1,5)); //node 14
    imageHierarchy.push_back(Vec4i(16,14,-1,5)); //node 15
    imageHierarchy.push_back(Vec4i(17,15,-1,5)); //node 16
    imageHierarchy.push_back(Vec4i(-1,16,-1,5)); //node 17


    MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:self.imageHierarchy imageContours:self.contours];
    
    NSDictionary *marker = [markerDetector findMarkers];
    STAssertEquals([marker count], (NSUInteger)1, @"Marker is not equal to 1.");
}

-(void)testFindMarkerWithOnlyRootNode
{
    //setup hierarchy for invalide code with only one node.
    imageHierarchy.push_back(Vec4i(-1,-1,-1,-1));
    MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:self.imageHierarchy imageContours:self.contours];
    NSDictionary *marker = [markerDetector findMarkers];
    STAssertEquals([marker count], (NSUInteger)0, @"Marker count should be 0");
}

-(void)testfindMarkerWithEmptyBranch
{
    
    //setup hierarchy for code 0:1:3:3:4
    //root node is 0 and it has children 1,2,3,4,5
    imageHierarchy.push_back(Vec4i(-1,-1,1,-1)); //node 0
    imageHierarchy.push_back(Vec4i(2,-1,6,0)); //node 1
    imageHierarchy.push_back(Vec4i(3,1,7,0)); //node 2.
    imageHierarchy.push_back(Vec4i(4,2,8,0)); //node 3
    imageHierarchy.push_back(Vec4i(5,3,11,0)); //node 4.
    imageHierarchy.push_back(Vec4i(-1,4,-1,0)); //node 5 is an empty branch so it has no child.
    
    imageHierarchy.push_back(Vec4i(-1,-1,-1,1)); //node 6
    
    //node 2 children
    imageHierarchy.push_back(Vec4i(-1,-1,-1,2)); //node 7
    
    //node 3 children
    imageHierarchy.push_back(Vec4i(9,-1,-1,3)); //node 8
    imageHierarchy.push_back(Vec4i(10,8,-1,3)); //node 9
    imageHierarchy.push_back(Vec4i(-1,9,-1,3)); //node 10
    
    //node 4 children
    imageHierarchy.push_back(Vec4i(12,-1,-1,4)); //node 11
    imageHierarchy.push_back(Vec4i(13,11,-1,4)); //node 12
    imageHierarchy.push_back(Vec4i(-1,12,-1,4)); //node 13
    
    MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:self.imageHierarchy imageContours:self.contours];
    
    NSDictionary *marker = [markerDetector findMarkers];
    STAssertEquals([marker count], (NSUInteger)0, @"Marker count should be equal to 0.");
}



@end
