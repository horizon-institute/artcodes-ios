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

#import "RgbColourFilter.h"
#import "ImageBuffers.h"

@implementation RedRgbFilterFactory
-(NSString*) name { return @"redFilter"; }
-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Red];
}
@end
@implementation GreenRgbFilterFactory
-(NSString*) name { return @"greenFilter"; }
-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Green];
}
@end
@implementation BlueRgbFilterFactory
-(NSString*) name { return @"blueFilter"; }
-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[RgbColourFilter alloc] initWithSettings:settings andChannel:BGRAChannel_Blue];
}
@end

@interface RgbColourFilter()

@property DetectionSettings* settings;
@property BGRAChannel channel;

@property cv::Mat extraChannelBuffer;
@property int* mix;

@end

@implementation RgbColourFilter

-(id)initWithSettings:(DetectionSettings*)settings andChannel:(BGRAChannel)channel
{
	if (self = [super init])
	{
		self.settings = settings;
		self.channel = channel;
		self.mix = NULL;
		return self;
	}
	return nil;
}

-(bool)requiresBgraInput
{
	return true;
}

/*
// avg 10-50ms on iPhone 6
-(void) process:(ImageBuffers*) buffers
{
	cv::vector<cv::Mat> bgra;
	cv::split(buffers.imageInBgr, bgra);
	// buffers.image = bgra.at(self.channel);
	[buffers setOutputAsImage:bgra.at(self.channel)];
}
*/

// avg <10ms on iPhone 6
-(void) process:(ImageBuffers*) buffers
{
	cv::vector<cv::Mat> input;
	cv::Mat colorImage = buffers.imageInBgr;
	input.push_back(colorImage);
	
	cv::vector<cv::Mat> output;
	cv::Mat greyOutputImage = buffers.outputBufferForGrey;
	output.push_back(greyOutputImage);
	if (self.extraChannelBuffer.rows==0)
	{
		if (colorImage.channels()==3)
		{
			self.extraChannelBuffer = cv::Mat(colorImage.cols, colorImage.rows, CV_8UC2);
		}
		else
		{
			self.extraChannelBuffer = cv::Mat(colorImage.cols, colorImage.rows, CV_8UC3);
		}
	}
	output.push_back(self.extraChannelBuffer);
	
	if (self.mix == NULL)
	{
		if (colorImage.channels()==3)
		{
			if (self.channel == BGRAChannel_Red)
			{
				self.mix = new int[6]{2, 0, 1, 1, 0, 2};
			}
			else if (self.channel == BGRAChannel_Green)
			{
				self.mix = new int[6]{2, 1, 1, 0, 0, 2};
			}
			else if (self.channel == BGRAChannel_Blue)
			{
				self.mix = new int[6]{2, 2, 1, 1, 0, 0};
			}
		}
		else if (colorImage.channels()==4)
		{
			if (self.channel == BGRAChannel_Red)
			{
				self.mix = new int[8]{2, 0, 1, 1, 0, 2, 3, 3};
			}
			else if (self.channel == BGRAChannel_Green)
			{
				self.mix = new int[8]{2, 1, 1, 0, 0, 2, 3, 3};
			}
			else if (self.channel == BGRAChannel_Blue)
			{
				self.mix = new int[8]{2, 2, 1, 1, 0, 0, 3, 3};
			}
		}
	}
	
	cv::mixChannels(input, output, self.mix, colorImage.channels());
	
	[buffers setOutputAsImage:greyOutputImage];
}

-(void)dealloc {
	if (self.mix != NULL)
	{
		delete[] self.mix;
	}
	self.extraChannelBuffer.release();
}

@end
