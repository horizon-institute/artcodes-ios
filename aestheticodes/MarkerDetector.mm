//
//  MarkerDetector.m
//  OpencvCamera
//
//  Created by horizon on 15/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerDetector.h"
#import "DtouchMarker.h"

enum BranchStatus{
    BRANCH_INVALID,
    BRANCH_EMPTY,
    BRANCH_VALID
};

@interface MarkerDetector()
@property vector<Vec4i> imageHierarchy;
@property NSMutableArray* markerCode;
-(BranchStatus)verifyBranchWithNodeIndex:(int)branchNodeIndex;
-(bool)isValidLeaf:(int)leafNodeIndex;
@end

@implementation MarkerDetector

const int CHILD_NODE_INDEX = 2;
const int NEXT_SIBLING_NODE_INDEX = 0;


@synthesize imageHierarchy;
@synthesize markerCode;

-(id)initWithImageHierarchy:(vector<Vec4i>) inImageHierarchy
{
    self = [super init];
    
    if (self){
        self.imageHierarchy = inImageHierarchy;
    }
    return self;
}

-(DtouchMarker*)getDtouchMarkerForNode:(int)nodeIndex{
    
    int currentBranchIndex;
    int numOfBranches = 0;
    int numOfEmptyBranches = 0;
    DtouchMarker* marker;
    
    markerCode = [[NSMutableArray alloc] init];
    
    //get the nodes of the root node.
    Vec4i nodes = imageHierarchy.at(nodeIndex);
    //get the first child node.
    currentBranchIndex = nodes[CHILD_NODE_INDEX];
    //if there is a branch node then verify branches.
    if (currentBranchIndex >= 0){
        //loop until there is a branch node.
        while (currentBranchIndex >= 0){
            BranchStatus branchStatus = [self verifyBranchWithNodeIndex:currentBranchIndex];
            if (branchStatus == BRANCH_VALID || branchStatus == BRANCH_EMPTY){
                numOfBranches++;
                if (branchStatus == BRANCH_EMPTY)
                    numOfEmptyBranches++;
                nodes = imageHierarchy.at(currentBranchIndex);
                currentBranchIndex = nodes[NEXT_SIBLING_NODE_INDEX];
            }
            else if (branchStatus == BRANCH_INVALID)
                break;
        }
    }
    
    if (markerCode.count > 0){
        marker = [[DtouchMarker alloc] init];
        marker.nodeIndex = nodeIndex;
        marker.occurence = 1;
        marker.code = markerCode;
    }
    
    return marker;
}

-(BranchStatus)verifyBranchWithNodeIndex:(int)branchNodeIndex
{
    int currentLeafIndex;
    int leafCount = 0;
    BranchStatus status = BRANCH_INVALID;
    
    Vec4i nodes = imageHierarchy.at(branchNodeIndex);
    currentLeafIndex = nodes[CHILD_NODE_INDEX];
    //if there is a leaf node
    if (currentLeafIndex >= 0)
    {
        while (currentLeafIndex >= 0){
            if ([self isValidLeaf:currentLeafIndex]){
                leafCount++;
                nodes = imageHierarchy.at(currentLeafIndex);
                //get sibling of the leaf node.
                currentLeafIndex = nodes[NEXT_SIBLING_NODE_INDEX];
            }else{
                status = BRANCH_INVALID;
                leafCount = -1;
                break;
            }
        }
    }
    if (leafCount == 0)
        status = BRANCH_EMPTY;
    else if (leafCount > 0){
        status = BRANCH_VALID;
        [markerCode addObject:[[NSNumber alloc] initWithInt:leafCount]];
    }
    return status;
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
