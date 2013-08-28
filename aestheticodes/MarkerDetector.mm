//
//  MarkerDetector.m
//  OpencvCamera
//
//  Created by horizon on 15/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerDetector.h"
#import "DtouchMarker.h"
#import "MarkerConstraint.h"

enum BranchStatus{
    BRANCH_INVALID,
    BRANCH_EMPTY,
    BRANCH_VALID
};

@interface BranchCode : NSObject
@property BranchStatus status;
@property int leafCount;
@end

@implementation BranchCode
@synthesize status;
@synthesize leafCount;
@end

@interface MarkerDetector()
@property vector<Vec4i> imageHierarchy;
@property vector<vector<cv::Point>> imageContours;

-(DtouchMarker*)newDtouchMarkerForNode:(int)nodeIndex;
-(BranchCode*)newBranchCodeForNodeIndex:(int)branchNodeIndex;
-(bool)isValidLeaf:(int)leafNodeIndex;
@end

@implementation MarkerDetector

const int CHILD_NODE_INDEX = 2;
const int NEXT_SIBLING_NODE_INDEX = 0;


@synthesize imageHierarchy;
@synthesize imageContours;

-(id)initWithImageHierarchy:(vector<Vec4i>)inImageHierarchy imageContours:(vector<vector<cv::Point>>)inImageContours
{
    self = [super init];
    
    if (self){
        imageHierarchy = inImageHierarchy;
        imageContours = inImageContours;
    }
    return self;
}

-(NSDictionary*)findMarkers{
    MarkerConstraint *markerConstraint = [[MarkerConstraint alloc] init];
    NSMutableDictionary* dtouchCodes = [NSMutableDictionary dictionary];
    for (int i = 0; i < imageContours.size(); i++)
    {
        DtouchMarker* newMarker = [self newDtouchMarkerForNode:i];
        if (newMarker != nil && [markerConstraint isValidDtouchMarker:newMarker]){
            //if code is already detected.
            DtouchMarker *marker = [dtouchCodes objectForKey:newMarker.codeKey];
            if (marker != nil){
                [marker addNodeIndex:i];
                
            }else{
                [dtouchCodes setObject:newMarker forKey:newMarker.codeKey];
            }
        }
    }
    return dtouchCodes;
}

-(DtouchMarker*)newDtouchMarkerForNode:(int)nodeIndex{
    
    int currentBranchIndex;
    int numOfBranches = 0;
    int numOfEmptyBranches = 0;
    DtouchMarker* marker;
    
    NSMutableArray* markerCode = [[NSMutableArray alloc] init];
    
    //get the nodes of the root node.
    Vec4i nodes = imageHierarchy.at(nodeIndex);
    //get the first child node.
    currentBranchIndex = nodes[CHILD_NODE_INDEX];
    //if there is a branch node then verify branches.
    if (currentBranchIndex >= 0){
        //loop until there is a branch node.
        while (currentBranchIndex >= 0){
            BranchCode *branchCode = [self newBranchCodeForNodeIndex:currentBranchIndex];
            if (branchCode.status == BRANCH_EMPTY)
                numOfEmptyBranches++;
            if (branchCode.status == BRANCH_VALID || branchCode.status == BRANCH_EMPTY){
                [markerCode addObject:[[NSNumber alloc] initWithInt:branchCode.leafCount]];
                numOfBranches++;
                nodes = imageHierarchy.at(currentBranchIndex);
                currentBranchIndex = nodes[NEXT_SIBLING_NODE_INDEX];
            }
            else if (branchCode.status == BRANCH_INVALID)
                break;
        }
    }
    if (markerCode.count > 0){
        marker = [[DtouchMarker alloc] init];
        [marker addNodeIndex:nodeIndex];
        marker.code = markerCode;
    }
    return marker;
}

-(BranchCode*)newBranchCodeForNodeIndex:(int)branchNodeIndex
{
    int currentLeafIndex;
    
    BranchCode *branchCode = [[BranchCode alloc] init];
    branchCode.status = BRANCH_INVALID;
    branchCode.leafCount = 0;
    
    Vec4i nodes = imageHierarchy.at(branchNodeIndex);
    currentLeafIndex = nodes[CHILD_NODE_INDEX];
    //if there is a leaf node
    if (currentLeafIndex >= 0)
    {
        while (currentLeafIndex >= 0){
            if ([self isValidLeaf:currentLeafIndex]){
                branchCode.leafCount++;
                nodes = imageHierarchy.at(currentLeafIndex);
                //get sibling of the leaf node.
                currentLeafIndex = nodes[NEXT_SIBLING_NODE_INDEX];
            }else{
                branchCode.status = BRANCH_INVALID;
                branchCode.leafCount = -1;
                break;
            }
        }
    }
    if (branchCode.leafCount == 0){
        branchCode.status = BRANCH_EMPTY;
    }
    else if (branchCode.leafCount > 0){
        branchCode.status = BRANCH_VALID;
    }
    return branchCode;
}

-(bool)isValidLeaf:(int)leafNodeIndex
{
    bool valid = false;
    Vec4i nodes = imageHierarchy.at(leafNodeIndex);
    //if leaf has child node
    if (nodes[CHILD_NODE_INDEX] >= 0){
        valid = false;
    }else
        valid = true;
    return valid;
}

@end
