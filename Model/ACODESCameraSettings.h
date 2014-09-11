//
//  ACODESCameraSettings.h
//  aestheticodes
//
//  Created by Will on 29/08/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

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
