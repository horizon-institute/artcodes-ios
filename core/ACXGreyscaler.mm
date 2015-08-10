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

#import "ACXGreyscaler.h"

@interface ACXGreyscaler ()

@property double hueShift;
@property bool invert;

-(ACXGreyscaler*)initWithHueShift:(double)hueShift invert:(bool)invert;

#ifdef __cplusplus

-(void)justHueShiftImage:(cv::Mat&)colorImage withBuffer:(cv::Mat&)bufferImage;

-(void)justGreyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage;
#endif

@end

@implementation ACXGreyscaler

-(ACXGreyscaler*)initWithHueShift:(double)hueShift invert:(bool)invert
{
	self = [super init];
	// hue should be in range [0-180]
	while (hueShift<0)
	{
		hueShift +=180;
	}
	while (hueShift>180)
	{
		hueShift -=180;
	}
	self.hueShift = hueShift;
	
	self.invert = invert;
	
	return self;
}

-(void)greyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage
{
	cv::Mat *ptrToColourImage = &colorImage;
	cv::Mat bufferImage;
	
	if (self.hueShift!=0)
	{
		bufferImage = cv::Mat(colorImage.size(), CV_8UC3);
		[self justHueShiftImage:colorImage withBuffer:bufferImage];
		ptrToColourImage = &bufferImage;
	}
	
	[self justGreyscaleImage:*ptrToColourImage to:greyscaleImage];
	
	if (self.invert)
	{
		bitwise_not(greyscaleImage, greyscaleImage);
	}
}

-(void)justHueShiftImage:(cv::Mat&)colorImage withBuffer:(cv::Mat&)bufferImage
{
	// convert to HSL (opencv can not do BGRA->HSLA so BGRA->BGR->HSL)
	cv::cvtColor(colorImage, bufferImage, CV_BGRA2BGR);
	cv::cvtColor(bufferImage, bufferImage, CV_BGR2HLS);
	
	// rotate hue value of ever pixel
	for (int y = 0; y < bufferImage.rows; y++)
	{
		cv::Vec3b* hslPixel = bufferImage.ptr<cv::Vec3b>(y);
		for (int x = 0; x < bufferImage.cols; x++, ++hslPixel)
		{
			int c = (*hslPixel).val[0];
			(*hslPixel).val[0] = (uchar) ((c+(int)self.hueShift)%181);
		}
	}
	
	// convert back to BGR
	cv::cvtColor(bufferImage, bufferImage, CV_HLS2BGR);
}

-(void)justGreyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage
{
	// USe a subclass to implement this method!
}

@end

@interface ACXGreyscalerRGB ()
@property cv::Mat weight;
@property bool intensity;
@end

@implementation ACXGreyscalerRGB

-(ACXGreyscalerRGB*)init
{
	return [self initWithHueShift:0 redMultiplier:0.299 greenMultiplier:0.587 blueMultiplier:0.114 invert:false];
}

-(ACXGreyscalerRGB*)initWithHueShift:(double)hueShift redMultiplier:(double)redMultiplier greenMultiplier:(double)greenMultiplier blueMultiplier:(double)blueMultiplier invert:(bool)invert
{
	self = [super initWithHueShift:hueShift invert:invert];
	
	self.weight = cv::Mat(1, self.hueShift==0?4:3, CV_32FC1, cv::Scalar(0));
	self.weight.at<float>(0, 0) = blueMultiplier;
	self.weight.at<float>(0, 1) = greenMultiplier;
	self.weight.at<float>(0, 2) = redMultiplier;
	
	self.intensity = redMultiplier==0.299 && greenMultiplier==0.587 && blueMultiplier==0.114;
	
	return self;
}

-(void)justGreyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage
{
	if (self.intensity)
	{
		cv::cvtColor(colorImage, greyscaleImage, colorImage.channels()==4 ? CV_BGRA2GRAY : CV_BGR2GRAY);
	}
	else
	{
		cv::transform(colorImage, greyscaleImage, self.weight);
	}
}

@end

@interface ACXGreyscalerCMYK ()
@property double C;
@property double M;
@property double Y;
@property double K;
@end

@implementation ACXGreyscalerCMYK

-(ACXGreyscalerCMYK*)initWithHueShift:(double)hueShift C:(double)C M:(double)M Y:(double)Y K:(double)K invert:(bool)invert
{
	self = [super initWithHueShift:hueShift invert:invert];
	self.C = C;
	self.M = M;
	self.Y = Y;
	self.K = K;
	return self;
}

-(void)justGreyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage
{
	for (int i = 0; i < colorImage.rows; ++i) {
		for (int j = 0; j < colorImage.cols; ++j) {
			cv::Vec3b *colorPixel = colorImage.ptr<cv::Vec3b>(i, j);
			
			double r = colorPixel->val[2] / 255.0;
			double g = colorPixel->val[1] / 255.0;
			double b = colorPixel->val[0] / 255.0;
			
			double k = MIN(1-r, MIN(1-g, 1-b));
			double c = (1-r-k) / (1-k);
			double m = (1-g-k) / (1-k);
			double y = (1-b-k) / (1-k);
			
			greyscaleImage.at<uchar>(i, j) = c*self.C*255 + m*self.M*255 + y*self.Y*255 + k*self.K*255;
		}
	}
}

@end


@interface ACXGreyscalerCMY ()
@property double C;
@property double M;
@property double Y;
@end

@implementation ACXGreyscalerCMY

-(ACXGreyscalerCMY*)initWithHueShift:(double)hueShift C:(double)C M:(double)M Y:(double)Y invert:(bool)invert
{
	self = [super initWithHueShift:hueShift invert:invert];
	self.C = C;
	self.M = M;
	self.Y = Y;
	return self;
}

-(void)justGreyscaleImage:(cv::Mat&)colorImage to:(cv::Mat&)greyscaleImage
{
	for (int i = 0; i < colorImage.rows; ++i) {
		for (int j = 0; j < colorImage.cols; ++j) {
			cv::Vec3b *colorPixel = colorImage.ptr<cv::Vec3b>(i, j);
			
			double r = colorPixel->val[2] / 255.0;
			double g = colorPixel->val[1] / 255.0;
			double b = colorPixel->val[0] / 255.0;
			
			double c = (1-r);
			double m = (1-g);
			double y = (1-b);
			
			greyscaleImage.at<uchar>(i, j) = c*self.C*255 + m*self.M*255 + y*self.Y*255;
		}
	}
}

@end
