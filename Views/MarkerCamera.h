/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import "ExperienceManager.h"
#import "ACODESCameraSettings.h"

@protocol MarkerFoundDelegate;
@class Experience;

@interface MarkerCamera : NSObject<CvVideoCameraDelegate>

@property (weak) ExperienceManager* experienceManager;

// Keep a strong reference to the camera settings as it will be distroyed and recreated when a new settings file is downloaded (which we replace this reference with when [self start] is called)
@property (strong) ACODESCameraSettings* cameraSettings;

// Mutex
@property bool newFrameAvaliable;
@property bool processingImage1;
@property NSLock *frameLock;

@property NSLock *detectingLock;

@property bool singleThread;
@property bool fullSizeViewFinder;
@property bool raisedTopBorder;


@property bool firstFrame;

- (void) stop;
- (void) start:(UIImageView*)imageView;
- (void)flip:(UIImageView*)imageView;

- (void) processFrame;

@end