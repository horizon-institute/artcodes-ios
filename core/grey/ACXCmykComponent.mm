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
#import "ACXCmykComponent.h"

@interface ACXCmykComponent ()
@property ACXCmykChannel channel;
@end

@implementation ACXCmykComponent

- (id) initWithChannel:(ACXCmykChannel)channel
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
			
			double r = colorPixel->val[2] / 255.0;
			double g = colorPixel->val[1] / 255.0;
			double b = colorPixel->val[0] / 255.0;
			
			double k = MIN(1-r, MIN(1-g, 1-b));
			if (self.channel == ACXCmykChannelCyan)
			{
				greyscaleImagePtr->at<uchar>(i, j) = 255 * (1-r-k);
			}
			else if (self.channel == ACXCmykChannelMagenta)
			{
				greyscaleImagePtr->at<uchar>(i, j) = 255 * (1-g-k);
			}
			else if (self.channel == ACXCmykChannelYellow)
			{
				greyscaleImagePtr->at<uchar>(i, j) = 255 * (1-b-k);
			}
			else //if (self.channel == ACXCmykChannelBlack)
			{
				greyscaleImagePtr->at<uchar>(i, j) = 255 * k;
			}
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
