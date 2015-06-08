/*
 * Aestheticodes recognises a different marker scheme that allows the
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
#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

/** 
 Class containing the method to greyscale an image.
 This is a base abstract class, use a subclass like ACXGreyscalerRGB or ACXGreyscalerCMYK 
 */
@interface ACXGreyscaler : NSObject
#ifdef __cplusplus
-(void)greyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage;
#endif
@end

/**
 Class containing the method to greyscale an image by weighting its colour components in the RGB space.
 */
@interface ACXGreyscalerRGB : ACXGreyscaler
-(ACXGreyscalerRGB*)init;
-(ACXGreyscalerRGB*)initWithHueShift:(double)hueShift redMultiplier:(double)redMultiplier greenMultiplier:(double)greenMultiplier blueMultiplier:(double)blueMultiplier invert:(bool)invert;
@end
/**
 Class containing the method to greyscale an image by weighting its colour components in the CMYK space.
 */
@interface ACXGreyscalerCMYK : ACXGreyscaler
-(ACXGreyscalerCMYK*)initWithHueShift:(double)hueShift C:(double)C M:(double)M Y:(double)Y K:(double)K invert:(bool)invert;
@end
/**
 Class containing the method to greyscale an image by weighting its colour components in the CMYK space.
 */
@interface ACXGreyscalerCMY : ACXGreyscaler
-(ACXGreyscalerCMY*)initWithHueShift:(double)hueShift C:(double)C M:(double)M Y:(double)Y invert:(bool)invert;
@end
