/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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
#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>

@interface ImageBuffers : NSObject

#ifdef __cplusplus
-(void)setNewFrame:(cv::Mat)newFrameImage;

/** The image in BGR CV_8UC3 or BGRA CV_8UC4. */
-(cv::Mat)imageInBgr;
/** The image in grey CV_8UC1. */
-(cv::Mat)imageInGrey;
/** The image in the format it was last used in. */
-(cv::Mat)image;
-(cv::Mat)overlay;
-(bool)hasOverlay;
-(void)clearOverlay;


/** Get the BGR image buffer without converting and filling it with the most recent data (may contain current, old or random data). */
-(cv::Mat)outputBufferForBgr;
/** Get the grey CV_8UC1 image buffer without converting and filling it with the most recent data (may contain current, old or random data). */
-(cv::Mat)outputBufferForGrey;

/** Set the given Mat as the current image. Can be a Mat acquired from ImageBuffers (e.g. outputBufferForBgr) or a new Mat but must be CV_8UC1, BGR CV_8UC3 or BGRA CV_8UC4. */
-(void)setOutputAsImage:(cv::Mat)output;
#endif

@end
