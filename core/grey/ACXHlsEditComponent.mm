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
#import "ACXHlsEditComponent.h"

@interface ACXHlsEditComponent ()

@property int hue, lightness, saturation;
@property cv::Mat *lut;

@end

@implementation ACXHlsEditComponent

- (ACXHlsEditComponent*) initWithHue:(int)hue lightness:(int)lightness saturation:(int)saturation
{
	self = [super init];
	if (self!=nil)
	{
		self.hue = hue;
		self.lightness = lightness;
		self.saturation = saturation;
		self.lut = NULL;
	}
	return self;
}


- (void) createLutMat
{
	[self releaseResources];
	self.lut = new cv::Mat(1, 256, CV_8UC3);
	
	float lightnessMultiplyer = ((self.lightness+255.0)/255.0);
	float saturationMultiplyer = ((self.saturation+255.0)/255.0);
	
	cv::Vec3b* hslPixel = self.lut->ptr<cv::Vec3b>(0);
	for (int value = 0; value < 256; ++value, ++hslPixel)
	{
		(*hslPixel).val[0] = (uchar) ((value+self.hue)%181);
		(*hslPixel).val[1] = (uchar) MIN(MAX(
											 (int)(value*lightnessMultiplyer)
											 ,0),255);
		(*hslPixel).val[2] = (uchar) MIN(MAX(
											 (int)(value*saturationMultiplyer)
											 ,0),255);
	}
}

- (void) process:(ACXBufferManager*)bufferManager
{
	cv::Mat *bgrBufferPtr = [bufferManager mostRecentDataInBgrBuffer];
	cv::Mat *threeChannelBufferPtr = [bufferManager threeChannelBuffer];
	
	if (bgrBufferPtr->channels()==4)
	{
		// convert to HSL (opencv can not do BGRA->HSLA so BGRA->BGR->HSL)
		cv::cvtColor(*bgrBufferPtr, *threeChannelBufferPtr, CV_BGRA2BGR);
		bgrBufferPtr = threeChannelBufferPtr;
	}
	cv::cvtColor(*bgrBufferPtr, *bgrBufferPtr, CV_BGR2HLS);
	
	if (self.lut==NULL)
	{
		[self createLutMat];
	}
	
	cv::LUT(*bgrBufferPtr, *self.lut, *bgrBufferPtr);
	
	// convert back to BGR
	cv::cvtColor(*bgrBufferPtr, *bgrBufferPtr, CV_HLS2BGR);
	[bufferManager setBgrBuffer:bgrBufferPtr];
}

- (bool) segmentSafe
{
	return true;
}

- (bool) segmentRecommended
{
	return true;
}

- (void) releaseResources
{
	if (self.lut!=NULL)
	{
		self.lut->release();
		delete self.lut;
		self.lut = NULL;
	}
}


@end
