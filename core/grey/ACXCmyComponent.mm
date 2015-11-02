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
#import "ACXCmyComponent.h"

@interface ACXCmyComponent ()
@property ACXCmyChannel channel;
@end

@implementation ACXCmyComponent

- (id) initWithChannel:(ACXCmyChannel)channel
{
	if (self=[super init])
	{
		self.channel = channel;
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) process:(ACXBufferManager*)bufferManager
{
	cv::Mat *colorImagePtr = [bufferManager mostRecentDataInBgrBuffer];
	cv::Mat *greyscaleImagePtr = [bufferManager greyBuffer];
	
	for (int i = 0; i < colorImagePtr->rows; ++i) {
		for (int j = 0; j < colorImagePtr->cols; ++j) {
			cv::Vec3b *colorPixel = colorImagePtr->ptr<cv::Vec3b>(i, j);
			greyscaleImagePtr->at<uchar>(i, j) = 255 - colorPixel->val[self.channel];
		}
	}
	
	[bufferManager setGreyBuffer:greyscaleImagePtr];
}

- (bool) segmentSafe
{
	return true;
}

- (bool) segmentRecommended
{
	return false;
}

- (void) releaseResources
{
}

@end
