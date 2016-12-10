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

#import "WhiteBalanceFilter.h"
#import "ImageBuffers.h"
#import <opencv2/opencv.hpp>

@implementation WhiteBalanceFilterFactory
-(NSString*) name { return @"whiteBalance"; }
-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[WhiteBalanceFilter alloc] init];
}
@end

@interface WhiteBalanceFilter ()

@property cv::Mat **histograms;
@property cv::Mat *emptyMatMask;
@property cv::Mat *lutBuffer;

@end

@implementation WhiteBalanceFilter

-(bool)requiresBgraInput
{
	return true;
}

- (id) init
{
	if (self=[super init])
	{
		self.histograms = NULL;
		self.emptyMatMask = NULL;
		self.lutBuffer = NULL;
		return self;
	}
	else
	{
		return nil;
	}
}

- (void) setupWithChannels:(int)channels
{
	self.histograms = new cv::Mat*[MIN(3,channels)];
	for (int channel=0; channel<MIN(3,channels); ++channel)
	{
		self.histograms[channel] = new cv::Mat();
	}
	self.emptyMatMask = new cv::Mat();
}

+ (void) getRemapForHistogram:(cv::Mat*)histogramPtr withTotal:(size_t)total remapA:(float*)resultA aIndex:(int)resultAIndex remapB:(float*)resultB bIndex:(int)resultBIndex
{
	size_t size = histogramPtr->total();
	if (total==-1)
	{
		total = 0;
		float *ptr = histogramPtr->ptr<float>();
		for (int i = 0; i < size; ++i, ++ptr)
		{
			total += *ptr;
		}
	}
	
	float p5 = total*0.05f, p95 = total*0.95f;
	resultB[resultBIndex] = resultA[resultAIndex] = -1;
	int count = 0;
	
	float *ptr = histogramPtr->ptr<float>();
	for (int i=0; i<size; ++i, ++ptr)
	{
		count += (int)*ptr;
		if (resultB[resultBIndex]==-1 && count>=p5)
		{
			resultB[resultBIndex] = i;
		}
		else if (count>=p95)
		{
			resultA[resultAIndex] = 255.0f/(i-resultB[resultBIndex]);
			break;
		}
	}
}

-(void) process:(ImageBuffers*) buffers
{
	cv::Mat image = buffers.imageInBgr;
	if (self.histograms==NULL)
	{
		[self setupWithChannels:image.channels()];
	}
	
	// create a histogram for each channel:
	int histSize[] = {256};
	float rgbRanges[] = { 0, 256 };
	const float* ranges[] = { rgbRanges };
	for (int channel=0; channel<MIN(3, image.channels()); ++channel)
	{
		cv::calcHist(
					 &image, // Ptr to images
					 1,		// Num of images
					 &channel, // Channels to use
					 *self.emptyMatMask, // Mask
					 *self.histograms[channel], // Histogram result
					 1, //histogram dims
					 histSize,
					 ranges);
	}
	
	float *a = new float[MIN(3,image.channels())];
	float *b = new float[MIN(3,image.channels())];
	
	// get the values to remap the histograms:
	for (int channel=0; channel<MIN(3,image.channels()); ++channel)
	{
		[WhiteBalanceFilter getRemapForHistogram:self.histograms[channel] withTotal:image.total() remapA:a aIndex:channel remapB:b bIndex:channel];
	}
	
	//NSLog(@"Remap: %f(x-%f), %f(x-%f), %f(x-%f)", a[0], b[0], a[1], b[1], a[2], b[2]);
	
	// Use a Look Up Table to re-map values
	// (it's a lot faster to workout and save what the 256 possible values transform into
	// than to do the math image.cols*rows times)
	
	if (self.lutBuffer==NULL)
	{
		self.lutBuffer = new cv::Mat(1, 256, CV_8UC(image.channels()));
	}
	cv::Mat *lut = self.lutBuffer;
	const int channels = image.channels();
	// Couldn't find a better way to select between cv::Vec4b and cv::Vec3b at runtime.
	if (channels==4)
	{
		cv::Vec4b *lutEntryPtr = lut->ptr<cv::Vec4b >(0);
		for (int i=0; i<256; ++i, ++lutEntryPtr)
		{
			for (int channel=0; channel<3; ++channel)
			{
				(*lutEntryPtr).val[channel] = (uchar) MIN(MAX(a[channel] * ((i) - b[channel]), 0), 255);
			}
			(*lutEntryPtr).val[3] = (uchar) 255;
		}
	}
	else if (channels==3)
	{
		cv::Vec3b *lutEntryPtr = lut->ptr<cv::Vec3b >(0);
		for (int i=0; i<256; ++i, ++lutEntryPtr)
		{
			for (int channel=0; channel<3; ++channel)
			{
				(*lutEntryPtr).val[channel] = (uchar) MIN(MAX(a[channel] * ((i) - b[channel]), 0), 255);
			}
		}
	}
	cv::LUT(image, *lut, image);
	[buffers setOutputAsImage:image];
	
	// Testing: To see the modified image on screen uncomment these lines:
	/*
	image.copyTo(buffers.overlay);
	cv::Mat o = buffers.overlay;
	cv::putText(o, @"white balence".fileSystemRepresentation, cv::Point(20,20), cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0,0,0,255), 2);
	 */
	
	delete [] a;
	delete [] b;
}

- (void) dealloc
{
	if (self.lutBuffer!=NULL)
	{
		delete self.lutBuffer;
		self.lutBuffer = NULL;
	}
	if (self.emptyMatMask!=NULL)
	{
		delete self.emptyMatMask;
		self.emptyMatMask = NULL;
	}
	if (self.histograms!=NULL)
	{
		for (int i=0; i<3; ++i)
		{
			delete self.histograms[i];
		}
		delete [] self.histograms;
		self.histograms = NULL;
	}
}

@end
