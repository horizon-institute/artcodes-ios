//
//  MarkerDetector.h
//  OpencvCamera
//
//  Created by horizon on 15/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DtouchMarker.h"

using namespace cv;

@interface MarkerDetector : NSObject

-(id)initWithImageHierarchy:(vector<Vec4i>) inImageHierarchy imageContours:(vector<vector<cv::Point>>)inImageContours;
-(NSDictionary*)findMarkers;
@end
