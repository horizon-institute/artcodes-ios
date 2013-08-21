//
//  MarkerDetectorTests.h
//  aestheticodes
//
//  Created by horizon on 20/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <opencv2/opencv.hpp>

using namespace cv;

@interface MarkerDetectorTests : SenTestCase

@property vector<Vec4i> imageHierarchy;
@property vector<vector<cv::Point>> contours;

@end
