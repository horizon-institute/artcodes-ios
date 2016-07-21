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

#import "CmykColourFilter.h"
#import "ImageBuffers.h"

@interface CmykColourFilter()

@property DetectionSettings* settings;
@property CMYKChannel channel;

@end

@implementation CmykColourFilter

-(id)initWithSettings:(DetectionSettings*)settings andChannel:(CMYKChannel)channel
{
	if (self = [super init])
	{
		self.settings = settings;
		self.channel = channel;
		return self;
	}
	return nil;
}

-(bool)requiresBgraInput
{
	return true;
}

-(void) process:(ImageBuffers*) buffers
{
	cv::Mat colorImage = buffers.image;
	cv::Mat greyscaleImage(colorImage.rows, colorImage.cols, CV_8UC1);
	
	for (int i = 0; i < colorImage.rows; ++i) {
		for (int j = 0; j < colorImage.cols; ++j) {
			cv::Vec3b *colorPixel = colorImage.ptr<cv::Vec3b>(i, j);
			
			double r = colorPixel->val[2] / 255.0;
			double g = colorPixel->val[1] / 255.0;
			double b = colorPixel->val[0] / 255.0;
			
			double k = MIN(1-r, MIN(1-g, 1-b));
			if (self.channel == CMYKChannel_Cyan)
			{
				greyscaleImage.at<uchar>(i, j) = 255 * (1-r-k);
			}
			else if (self.channel == CMYKChannel_Magenta)
			{
				greyscaleImage.at<uchar>(i, j) = 255 * (1-g-k);
			}
			else if (self.channel == CMYKChannel_Yellow)
			{
				greyscaleImage.at<uchar>(i, j) = 255 * (1-b-k);
			}
			else //if (self.channel == CMYKChannel_Black)
			{
				greyscaleImage.at<uchar>(i, j) = 255 * k;
			}
		}
	}
	
	buffers.image = greyscaleImage;
}

@end
