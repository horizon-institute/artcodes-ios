//
//  TileThreshold.h
//  Artcodes
//
//  Created by Kevin Glover on 20 Oct 2015.
//  Copyright © 2015 Horizon DER Institute. All rights reserved.
//

#import "ImageProcessor.h"

@class DetectionSettings;

@interface TileThreshold : NSObject<ImageProcessor>

-(id)initWithSettings:(DetectionSettings*)settings;
-(cv::Mat) process:(cv::Mat) image withOverlay:(cv::Mat) overlay;

@end
