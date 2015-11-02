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
#import "ACXRgbComponent.h"

@interface ACXRgbComponent ()
@property ACXRgbChannel channel;
@property cv::Mat* weight;
@end

@implementation ACXRgbComponent

- (ACXRgbComponent*) initWithChannel:(ACXRgbChannel)channel
{
	self = [super init];
	if (self!=nil)
	{
		self.channel = channel;
		self.weight = NULL;
	}
	return self;
}

- (void) createWeightMatWithChannels:(int)channels
{
	[self releaseResources];
	self.weight = new cv::Mat(1, channels, CV_32FC1, cv::Scalar(0));
	switch (self.channel) {
		case ACXRgbChannelRed:
			self.weight->at<float>(0, 2) = 1;
			break;
		case ACXRgbChannelGreen:
			self.weight->at<float>(0, 1) = 1;
			break;
		case ACXRgbChannelBlue:
			self.weight->at<float>(0, 0) = 1;
			break;
		default:
			break;
	}
}

uchar ch0 (cv::Vec3b i) { return i[0]; }
uchar ch1 (cv::Vec3b i) { return i[1]; }
uchar ch2 (cv::Vec3b i) { return i[2]; }

- (void) process:(ACXBufferManager*)bufferManager
{
	cv::Mat *bgrBufferPtr = [bufferManager mostRecentDataInBgrBuffer];
	cv::Mat *greyBufferPtr = [bufferManager greyBuffer];
	if (self.weight==NULL || bgrBufferPtr->channels()!=self.weight->cols)
	{
		[self createWeightMatWithChannels:bgrBufferPtr->channels()];
	}
	cv::transform(*bgrBufferPtr, *greyBufferPtr, *self.weight);
	
	[bufferManager setGreyBuffer:greyBufferPtr];
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
	if (self.weight!=NULL)
	{
		self.weight->release();
		delete self.weight;
		self.weight = NULL;
	}
}

@end
