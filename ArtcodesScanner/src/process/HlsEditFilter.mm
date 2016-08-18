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

#import "HlsEditFilter.h"
#import "ImageBuffers.h"
#import <opencv2/opencv.hpp>

@implementation HlsEditFilterFactory
-(NSString*) name { return @"hlsEdit"; }
-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	int hueShift=0, lightnessAddition=0, saturationAddition=0;
	
	static NSArray *HUE_KEYS = [[NSArray alloc] initWithObjects:@"hue", @"hueShift", @"h", nil];
	static NSArray *LIGHTNESS_KEYS = [[NSArray alloc] initWithObjects:@"lightness", @"l", nil];
	static NSArray *SATURATION_KEYS = [[NSArray alloc] initWithObjects:@"saturation", @"s", nil];
	
	if (args != nil)
	{
		for (NSString *key in HUE_KEYS)
		{
			if (args[key] != nil)
			{
				hueShift = [args[key] intValue];
			}
		}
		for (NSString *key in LIGHTNESS_KEYS)
		{
			if (args[key] != nil)
			{
				lightnessAddition = [args[key] intValue];
			}
		}
		for (NSString *key in SATURATION_KEYS)
		{
			if (args[key] != nil)
			{
				saturationAddition = [args[key] intValue];
			}
		}
	}

	return [[HlsEditFilter alloc] initWithHue: hueShift lightness: lightnessAddition saturation: saturationAddition];
}
@end

@interface HlsEditFilter ()

@property int hue, lightness, saturation;
@property cv::Mat *lut;
@property cv::Mat threeChannelBuffer;

@end

@implementation HlsEditFilter

- (HlsEditFilter*) initWithHue:(int)hueShift lightness:(int)lightnessAddition saturation:(int)saturationAddition
{
	self = [super init];
	if (self!=nil)
	{
		self.lut = NULL;
		
		
		// hue input range: [0,360] change to range: [0,180]
		self.hue = (hueShift / 2) % 181;
		
		// lightness input range: [-100,100] change to range: [-255,255]
		self.lightness = MIN(MAX((int) (lightnessAddition*2.55),-255),255);
		
		// saturation input range: [-100,100] change to range: [-255,255]
		self.saturation = MIN(MAX((int) (saturationAddition*2.55),-255),255);
		
	}
	return self;
}

-(bool)requiresBgraInput
{
	return true;
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

-(void) process:(ImageBuffers*) buffers
{
	cv::Mat bgrMatFromBuffer = [buffers imageInBgr];
	cv::Mat bgrImage;
	if (bgrMatFromBuffer.channels()==4)
	{
		if (self.threeChannelBuffer.rows == 0)
		{
			self.threeChannelBuffer = cv::Mat(bgrMatFromBuffer.cols, bgrMatFromBuffer.rows, CV_8UC3);
		}
		// convert to HSL (opencv can not do BGRA->HSLA so BGRA->BGR->HSL)
		cv::cvtColor(bgrMatFromBuffer, self.threeChannelBuffer, CV_BGRA2BGR);
		bgrImage = self.threeChannelBuffer;
	}
	else
	{
		bgrImage = bgrMatFromBuffer;
	}
	cv::cvtColor(bgrImage, bgrImage, CV_BGR2HLS);
	
	if (self.lut==NULL)
	{
		[self createLutMat];
	}
	
	cv::LUT(bgrImage, *self.lut, bgrImage);
	
	// convert back to BGR
	cv::cvtColor(bgrImage, bgrImage, CV_HLS2BGR);
	if (bgrMatFromBuffer.channels() == 4)
	{
		cv::cvtColor(bgrImage, bgrMatFromBuffer, CV_BGR2BGRA);
	}
	[buffers setOutputAsImage:bgrMatFromBuffer];
	
	
	// Testing: To see the modified image on screen uncomment these lines:
	/*
	 bgrMatFromBuffer.copyTo(buffers.overlay);
	 cv::Mat o = buffers.overlay;
	 cv::putText(o, @"hls edit".fileSystemRepresentation, cv::Point(20,20), cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0,0,0,255), 2);
	 */
	 
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
- (void) dealloc
{
	[self releaseResources];
}



@end
