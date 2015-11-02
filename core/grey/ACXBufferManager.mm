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
#import "ACXBufferManager.h"

@interface ACXBufferManager ()

@property cv::Mat *bgrBufferPtr;
@property cv::Mat *greyBufferPtr;
@property cv::Mat *threeChannelBufferPtr;
@property cv::Mat *mostRecentDataPtr;
@property bool ownBgrBuffer;
@property bool ownGreyBuffer;

@end

@implementation ACXBufferManager

- (void) logMethod:(NSString*)method
{
	NSLog(@"In %@", method);
	[ACXBufferManager logImagePtr:self.bgrBufferPtr withName:@"bgr_"];
	[ACXBufferManager logImagePtr:self.greyBufferPtr withName:@"grey"];
}
	
+ (void) logImagePtr:(cv::Mat*)imgPtr withName:(NSString*)imgName
{
	if (imgPtr==NULL)
	{
		NSLog(@"- Image %@ is NULL.", imgName);
	}
	else
	{
		NSLog(@"- Image %@(%d): %dx%dx%d", imgName, imgPtr, imgPtr->cols, imgPtr->rows, imgPtr->channels());
	}
}

- (id)init
{
	if (self=[super init])
	{
		self.bgrBufferPtr = NULL;
		self.greyBufferPtr = NULL;
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) setupWithBgrSource:(cv::Mat*)bgrSourcePtr andGreyResultBuffer:(cv::Mat*)greyResultPtr
{
	self.mostRecentDataPtr = self.bgrBufferPtr = bgrSourcePtr;
	self.greyBufferPtr = greyResultPtr;
	
	if (self.greyBufferPtr!=NULL)
	{
		if (self.bgrBufferPtr->rows != self.greyBufferPtr->rows || self.bgrBufferPtr->cols != self.greyBufferPtr->cols)
		{
			if (self.bgrBufferPtr->cols == self.greyBufferPtr->rows && self.bgrBufferPtr->rows == self.greyBufferPtr->cols)
			{
				cv::transpose(*self.greyBufferPtr, *self.greyBufferPtr);
			}
			else
			{
				self.greyBufferPtr->release();
				self.greyBufferPtr = new cv::Mat(self.bgrBufferPtr->size(), CV_8UC1);
				self.ownGreyBuffer = true;
			}
		}
	}
}

- (void) setBgrBuffer:(cv::Mat*)bgrBufferPtr
{
	self.mostRecentDataPtr = self.bgrBufferPtr = bgrBufferPtr;
}
- (void) setGreyBuffer:(cv::Mat*)greyBufferPtr
{
	self.mostRecentDataPtr = self.greyBufferPtr = greyBufferPtr;
}

- (cv::Mat*) bgrBuffer
{
	if (self.bgrBufferPtr==NULL)
	{
		if (self.greyBufferPtr!=NULL)
		{
			self.bgrBufferPtr = new cv::Mat(self.greyBufferPtr->size(), CV_8UC3);
			self.ownBgrBuffer = true;
		}
	}
	return self.bgrBufferPtr;
}
- (cv::Mat*) greyBuffer
{
	if (self.greyBufferPtr==NULL)
	{
		if (self.bgrBufferPtr!=NULL)
		{
			self.greyBufferPtr = new cv::Mat(self.bgrBufferPtr->size(), CV_8UC3);
			self.ownGreyBuffer = true;
		}
	}
	return self.greyBufferPtr;
}

- (cv::Mat*)threeChannelBuffer
{
	if (self.bgrBufferPtr == NULL || self.bgrBufferPtr->channels() == 3)
	{
		return [self bgrBuffer];
	}
	else if (self.threeChannelBufferPtr==NULL)
	{
		self.threeChannelBufferPtr = new cv::Mat(self.bgrBufferPtr->size(), CV_8UC3);
	}
	return self.threeChannelBufferPtr;
}

- (cv::Mat*) mostRecentDataInBgrBuffer
{
	if (self.bgrBufferPtr==NULL)
	{
		[self bgrBuffer];
	}
	
	if (self.mostRecentDataPtr==self.bgrBufferPtr)
	{
		return self.bgrBufferPtr;
	}
	else if (self.mostRecentDataPtr==self.greyBufferPtr)
	{
		cv::cvtColor(*self.greyBufferPtr, *self.bgrBufferPtr, self.bgrBufferPtr->channels()==4?CV_GRAY2BGRA:CV_GRAY2BGR);
		return self.bgrBufferPtr;
	}
	else
	{
		return NULL;
	}
}
- (cv::Mat*) mostRecentDataInGreyBuffer
{
	if (self.greyBufferPtr==NULL)
	{
		[self greyBuffer];
	}
	
	if (self.mostRecentDataPtr==self.bgrBufferPtr)
	{
		cv::cvtColor(*self.bgrBufferPtr, *self.greyBufferPtr, self.bgrBufferPtr->channels()==4?CV_BGRA2GRAY:CV_BGR2GRAY);
		return self.greyBufferPtr;
	}
	else if (self.mostRecentDataPtr==self.greyBufferPtr)
	{
		return self.greyBufferPtr;
	}
	else
	{
		return NULL;
	}
}
- (cv::Mat*) mostRecentData
{
	return self.mostRecentDataPtr;
}

- (void) releaseResources
{
	if (self.threeChannelBufferPtr!=NULL)
	{
		self.threeChannelBufferPtr->release();
		delete self.threeChannelBufferPtr;
		if (self.bgrBufferPtr==self.threeChannelBufferPtr)
		{
			self.bgrBufferPtr = NULL;
		}
		self.threeChannelBufferPtr = NULL;
	}
	
	if (self.ownBgrBuffer && self.bgrBufferPtr != NULL)
	{
		self.bgrBufferPtr->release();
		delete self.bgrBufferPtr;
		self.bgrBufferPtr = NULL;
	}
	
	if (self.ownGreyBuffer && self.greyBufferPtr != NULL)
	{
		self.greyBufferPtr->release();
		delete self.greyBufferPtr;
		self.greyBufferPtr = NULL;
	}
}

@end
