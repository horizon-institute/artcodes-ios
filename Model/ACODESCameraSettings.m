//
//  ACODESCameraSettings.m
//  aestheticodes
//
//  Created by Will on 29/08/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

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
