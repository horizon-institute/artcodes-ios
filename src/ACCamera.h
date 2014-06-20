//
//  ACCamera.h
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface ACCamera : NSObject<CvVideoCameraDelegate>

@property int drawMode;

- (void) stop;
- (void) start;
- (BOOL) isRunning;

@end