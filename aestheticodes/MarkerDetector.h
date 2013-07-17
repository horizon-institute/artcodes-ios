//
//  MarkerDetector.h
//  OpencvCamera
//
//  Created by horizon on 15/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>

using namespace cv;

@interface MarkerDetector : NSObject

-(NSArray*)verifyRootWithRootIndex:(NSInteger)rootIndex imageHierarchy:(vector<Vec4i>)hierarchy;

@end
