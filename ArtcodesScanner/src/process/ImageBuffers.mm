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
#import "ImageBuffers.h"

@interface ImageBuffers ()
@property cv::Mat bgrBuffer;
@property cv::Mat greyBuffer;
@property bool bgrBufferInit;
@property bool greyBufferInit;
@property bool currentBufferIsGrey;
@end

@implementation ImageBuffers

-(void)setNewFrame:(cv::Mat)newFrameImage
{
	if (newFrameImage.channels() == 1)
	{
		self.greyBuffer = newFrameImage;
		self.currentBufferIsGrey = true;
		self.greyBufferInit = true;
	}
	else if (newFrameImage.channels() == 3 || newFrameImage.channels() == 4)
	{
		self.bgrBuffer = newFrameImage;
		self.currentBufferIsGrey = false;
		self.bgrBufferInit = true;
	}
}

-(cv::Mat)imageInBgr
{
	[self createBgrBufferIfNeeded];
	if (self.currentBufferIsGrey && self.greyBufferInit)
	{
		cv::cvtColor(self.greyBuffer, self.bgrBuffer, self.bgrBuffer.channels()==3 ? cv::COLOR_GRAY2BGR : cv::COLOR_GRAY2BGRA);
	}
	self.currentBufferIsGrey = false;
	return self.bgrBuffer;
}
-(cv::Mat)imageInGrey
{
	[self createGreyBufferIfNeeded];
	if (!self.currentBufferIsGrey && self.bgrBufferInit)
	{
		cv::cvtColor(self.bgrBuffer, self.greyBuffer, self.bgrBuffer.channels()==3 ? cv::COLOR_BGR2GRAY : cv::COLOR_BGRA2GRAY);
	}
	self.currentBufferIsGrey = true;
	return self.greyBuffer;
}

-(cv::Mat)image
{
	if (self.currentBufferIsGrey && self.greyBufferInit)
	{
		return self.greyBuffer;
	}
	else if (self.bgrBufferInit)
	{
		return self.bgrBuffer;
	}
	return cv::Mat();
}

-(cv::Mat)outputBufferForBgr
{
	[self createBgrBufferIfNeeded];
	return self.bgrBuffer;
}
-(cv::Mat)outputBufferForGrey
{
	[self createGreyBufferIfNeeded];
	return self.greyBuffer;
}

-(void)setOutputAsImage:(cv::Mat)output
{
	if (self.greyBufferInit && output.ptr() == self.greyBuffer.ptr())
	{
		self.currentBufferIsGrey = true;
	}
	else if (self.bgrBufferInit && output.ptr() == self.bgrBuffer.ptr())
	{
		self.currentBufferIsGrey = false;
	}
	else
	{
		[self setNewFrame:output];
	}
}

-(void)createBgrBufferIfNeeded
{
	if (!self.bgrBufferInit && self.greyBufferInit)
	{
		self.bgrBuffer = cv::Mat(self.greyBuffer.cols, self.greyBuffer.rows, CV_8UC3);
		self.bgrBufferInit = true;
	}
}
-(void)createGreyBufferIfNeeded
{
	if (!self.greyBufferInit && self.bgrBufferInit)
	{
		self.greyBuffer = cv::Mat(self.bgrBuffer.cols, self.bgrBuffer.rows, CV_8UC1);
		self.greyBufferInit = true;
	}
}

@end
