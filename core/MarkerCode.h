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

/** The region value's key in an NSDictionary. */
FOUNDATION_EXPORT NSString *const REGION_VALUE;
/** The region indexes key in an NSDictionary. */
FOUNDATION_EXPORT NSString *const REGION_INDEX;

/** Class to store the details of a marker occurrence.  */
@interface ACXMarkerDetails : NSObject
/** An array of dictionaries, each sorting details about a region */
@property NSMutableArray* regions;
@property NSNumber* embeddedChecksum;
@property NSNumber* embeddedChecksumRegionIndex;
@property int markerIndex;
-(ACXMarkerDetails*)initWithDetails:(ACXMarkerDetails*)details;
@end

/** Interface for a class that can draw a marker. */
@protocol ACXMarkerDrawer <NSObject>
#ifdef __cplusplus
-(void)drawMarker:(MarkerCode*)marker forImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor;
#endif
@end

@interface MarkerCode : NSObject
@property NSString* codeKey;
@property (readonly) int emptyRegionCount;
@property (readonly) int regionCount;
@property long occurence;
@property NSMutableArray* markerDetails;

-(MarkerCode*)initWithCodeKey:(NSString*)code andDetails:(ACXMarkerDetails*)details  andDrawer:(id<ACXMarkerDrawer>)drawer;

/** Add the occurences of another MarkerCode (with the same code) to this MarkerCode. */
-(void)addMarkerInstance:(MarkerCode*)marker;

#ifdef __cplusplus
-(void)drawMarkerForImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor;
#endif

@end
