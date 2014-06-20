//
//  ACCamera.h
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

@protocol MarkerFoundDelegate;
@class MarkerSettings;

@interface ACCamera : NSObject<CvVideoCameraDelegate>

@property NSInteger drawMode;
@property (weak) id <MarkerFoundDelegate> markerDelegate;
@property (weak) MarkerSettings* settings;

- (void) stop;
- (void) start:(UIImageView*)imageView;

@end