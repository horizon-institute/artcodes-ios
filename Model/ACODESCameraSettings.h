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

@interface ACODESCameraSettings : NSObject

-(void)loadSettingsData:(NSDictionary*) data;


@property (nonatomic, retain) NSString* aVCaptureSessionPreset;
@property (nonatomic, retain) NSArray* resolution;
@property (nonatomic) int defaultFPS;
@property (nonatomic) int roiTop;
@property (nonatomic) int roiLeft;
@property (nonatomic) int roiHeight;
@property (nonatomic) int roiWidth;
@property (nonatomic) bool singleThreaded;
@property (nonatomic, retain) NSArray* viewfinderOptions;

-(NSString *const)getAVCaptureSessionPreset;
-(int)getResolutionX;
-(int)getResolutionY;
-(int)getDefaultFPS;
-(bool)shouldUseSingleThread;

-(bool)shouldUseFullscreenViewfinder;
-(bool)shouldUseReducedSizeViewfinder;
-(bool)shouldUseRaisedTopBarViewfinder;
-(bool)shouldUseSideBarsViewfinder;

@end
