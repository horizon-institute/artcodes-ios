//
//  ACCamera.h
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import "MarkerFoundDelegate.h"

@protocol MarkerFoundDelegate;
@class MarkerSettings;

@interface MarkerCamera : NSObject<CvVideoCameraDelegate>

@property NSString* mode;
@property (weak) id <MarkerFoundDelegate> markerDelegate;
@property (weak) MarkerSettings* settings;

// Mutex
@property bool newFrameAvaliable;
@property bool processingImage1;
@property NSLock *frameLock;

- (void) stop;
- (void) start:(UIImageView*)imageView;
- (void)flip:(UIImageView*)imageView;

@end