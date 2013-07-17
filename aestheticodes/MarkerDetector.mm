//
//  MarkerDetector.m
//  OpencvCamera
//
//  Created by horizon on 15/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "MarkerDetector.h"

@interface MarkerDetector(){
@private
    
    
}
@end

@implementation MarkerDetector

int const CHILD_NODE_INDEX = 2;

-(NSArray*)verifyRootWithRootIndex:(int)rootIndex imageHierarchy:(vector<Vec4i>)hierarchy{
    
    int currentBranchIndex;
    
    //get the nodes of the root node.
    Vec4i nodes = hierarchy.at(rootIndex);
    //get the first child node.
    currentBranchIndex = nodes[CHILD_NODE_INDEX];
    //if there is a branch node then verify branches.
    if (currentBranchIndex >= 0){
        //loop until there is a branch node.
        while (currentBranchIndex >= 0){
            
        }
    }
    
}

/*
-(NSArray*)getBranchCodesForBranch:(int)branchIndex imageHierarchy{
    return nil;
}*/

@end
