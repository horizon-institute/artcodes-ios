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

@interface ACXBufferManager : NSObject

- (void) logMethod:(NSString*)method;

#ifdef __cplusplus

- (void) setupWithBgrSource:(cv::Mat*)bgrSourcePtr andGreyResultBuffer:(cv::Mat*)greyResultPtr;

- (void) setBgrBuffer:(cv::Mat*)bgrBufferPtr;
- (void) setGreyBuffer:(cv::Mat*)greyBufferPtr;

- (cv::Mat*) bgrBuffer;
- (cv::Mat*) greyBuffer;
- (cv::Mat*) threeChannelBuffer;

- (cv::Mat*) mostRecentDataInBgrBuffer;
- (cv::Mat*) mostRecentDataInGreyBuffer;
- (cv::Mat*) mostRecentData;

#endif

- (void) releaseResources;

@end
