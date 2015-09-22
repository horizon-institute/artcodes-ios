//
//  FrameProcessor.h
//  artcodes
//
//  Created by Kevin Glover on 12/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

#ifndef artcodes_FrameProcessor_h
#define artcodes_FrameProcessor_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureOutput.h>
#import <UIKit/UIKit.h>

@class MarkerSettings;

@interface FrameProcessor : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak) MarkerSettings* settings;
@property (weak) UIImageView* overlay;

@end

#endif