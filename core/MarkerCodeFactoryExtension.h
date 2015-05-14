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
#import "MarkerCodeFactory.h"
#import "MarkerCode.h"

@interface MarkerCodeFactory () <ACXMarkerDrawer>

/* The creation of a MarkerCode is broken into many smaller tasks (called in the order below). To create new kinds of markers you may only need to override one or two of these tasks. */

#ifdef __cplusplus
/** Override this method to change the order tasks are done in, or to preform additional tasks inbetween those below */
-(ACXMarkerDetails*)createMarkerDetailsForNode:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error;
#endif

#ifdef __cplusplus
/** Override this method if you want to parse additional information about codes (e.g. area). You may want to call the default implementation to parse the region indexes/values for you. */
-(ACXMarkerDetails*)parseRegionsAt:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error;
#endif

/** Override this method to change the sorted order of the code. */
-(void)sortCode:(ACXMarkerDetails*)details;

/** Override this method to change validation method. */
-(bool)validate:(ACXMarkerDetails*)details withExperience:(Experience*)experience error:(DetectionError*)error;

/** Override this method if your marker-code string representation is more complicated than an ordered list of numbers seperated by colons. */
-(NSString*)getCodeFor:(ACXMarkerDetails*)details;

@end

