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
#import "ExperienceController.h"
#import "ACODESCameraSettings.h"

typedef enum
{
	displaymarker_off = 1,
	displaymarker_outline,
	displaymarker_on
} MarkerDisplayMode;

@protocol ScanDelegate <NSObject>

-(void)markersFound:(NSDictionary*)markers;

@end

@class Experience;

@interface MarkerCamera : NSObject<CvVideoCameraDelegate>

@property bool fullSizeViewFinder;

@property (weak) ExperienceController* experience;
@property (weak) id<ScanDelegate> delegate;

@property (nonatomic) bool rearCamera;
@property (nonatomic) bool displayThreshold;
@property (nonatomic) MarkerDisplayMode displayMarker;

- (void) stop;
- (void) start:(UIImageView*)imageView;

@end