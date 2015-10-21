//
//  ImageProcessor.h
//  Artcodes
//
//  Created by Kevin Glover on 20 Oct 2015.
//  Copyright © 2015 Horizon DER Institute. All rights reserved.
//

#ifndef ImageProcessor_h
#define ImageProcessor_h

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>

@class DetectionSettings;

@protocol ImageProcessor <NSObject>

-(cv::Mat) process:(cv::Mat) image withOverlay:(cv::Mat) overlay;

@end

#endif /* ImageProcessor_h */
