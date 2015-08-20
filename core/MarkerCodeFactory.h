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

@class MarkerCode;
@class Experience;

/** Possible error states that can be set when creating a MarkerCode */
typedef enum {
	unknown, noSubContours, tooManyEmptyRegions, nestedRegions, numberOfRegions, numberOfDots, checksum, validationRegions, extensionSpecificError, OK
} DetectionError;

@interface MarkerCodeFactory : NSObject

#ifdef __cplusplus
/**
 Generate any additional information from the image required for creating or drawing markers.
 
 Note: The MarkerCodeFactory instance holds on to the generated information, and replaces it with each call, so make sure to do all your MarkerCode creation and drawing before calling this again. Alternativly two or more instances of the MarkerCodeFactory sub-class can be used.
 */
-(void)generateExtraFrameDetailsForThresholdedImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy;

/** Create a MarkerCode */
-(MarkerCode*)createMarkerForNode:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error;
#endif

@end

