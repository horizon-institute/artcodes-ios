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
#import <AVFoundation/AVCaptureSession.h>
#import "ACODESCameraSettings.h"

@implementation ACODESCameraSettings

-(void)loadSettingsData:(NSDictionary*) json
{
    // load
    self.aVCaptureSessionPreset = [json valueForKey:@"AVCaptureSessionPreset"];
    self.resolution = [json valueForKey:@"resolution"];
    self.defaultFPS = (int)[json[@"defaultFps"] integerValue];
    self.singleThreaded = [json valueForKey:@"singleThread"];
    self.viewfinderOptions = [json valueForKey:@"viewfinderOptions"];
    
    NSDictionary* regionOfInterest = [json valueForKey:@"regionOfInterest"];
    if (regionOfInterest)
    {
        self.roiTop = (int) [[regionOfInterest valueForKey:@"top"] integerValue];
        self.roiLeft = (int) [[regionOfInterest valueForKey:@"left"] integerValue];
        self.roiHeight = (int) [[regionOfInterest valueForKey:@"height"] integerValue];
        self.roiWidth = (int) [[regionOfInterest valueForKey:@"width"] integerValue];
    }
    else
    {
        self.roiTop = 0;
        self.roiLeft = 0;
        self.roiHeight = [self getResolutionX];
        self.roiWidth = [self getResolutionY];
    }
}

-(NSString *const)getAVCaptureSessionPreset
{
    if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPresetiFrame1280x720"])
    {
        return AVCaptureSessionPresetiFrame1280x720;
    }
    else if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPresetiFrame960x540"])
    {
        return AVCaptureSessionPresetiFrame960x540;
    }
    else if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPreset1920x1080"])
    {
        return AVCaptureSessionPreset1920x1080;
    }
    else if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPreset1280x720"])
    {
        return AVCaptureSessionPreset1280x720;
    }
    else if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPreset640x480"])
    {
        return AVCaptureSessionPreset640x480;
    }
    else if ([self.aVCaptureSessionPreset isEqualToString:@"AVCaptureSessionPreset352x288"])
    {
        return AVCaptureSessionPreset352x288;
    }
    else
    {
        NSLog(@"Error, AVCaptureSessionPreset resolution setting not found.");
        return nil;
    }
}
-(int)getResolutionX
{
    return [[self.resolution objectAtIndex:0] intValue];
}
-(int)getResolutionY
{
    return [[self.resolution objectAtIndex:1] intValue];
}
-(int)getDefaultFPS
{
    return self.defaultFPS;
}
-(bool)shouldUseSingleThread
{
    return self.singleThreaded;
}

-(bool)shouldUseFullscreenViewfinder
{
    return [self.viewfinderOptions containsObject:@"fullscreen"];
}
-(bool)shouldUseReducedSizeViewfinder
{
    return [self.viewfinderOptions containsObject:@"reduced size"];
}
-(bool)shouldUseRaisedTopBarViewfinder
{
    return [self.viewfinderOptions containsObject:@"raised top bar"];
}
-(bool)shouldUseSideBarsViewfinder
{
    return [self.viewfinderOptions containsObject:@"side bars"];
}


@end
