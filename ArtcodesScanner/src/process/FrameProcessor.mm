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

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import "FrameProcessor.h"
#import "ImageProcessor.h"
#import "TileThreshold.h"
#import "MarkerDetector.h"

@interface FrameProcessor()

@property (nonatomic) cv::Mat* overlayImage;
@property NSArray* pipeline;
@property DetectionSettings* settings;

@end

@implementation FrameProcessor

-(void) createPipeline:(NSArray *)pipeline andSettings:(DetectionSettings*) settings
{
	//for(NSString* processor in pipeline)
	//{
	//	TODO
	//}
	
	NSMutableArray* newPipeline = [[NSMutableArray alloc] init];
	[newPipeline addObject:[[TileThreshold alloc] initWithSettings:settings]];
	[newPipeline addObject:[[MarkerDetector alloc] initWithSettings:settings]];
	
	self.pipeline = newPipeline;
	self.settings = settings;
}

-(void) captureOutput: ( AVCaptureOutput * ) captureOutput
	didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer
	fromConnection: ( AVCaptureConnection * ) connection
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	CVPixelBufferLockBaseAddress( imageBuffer, 0 );
	
	cv::Mat image = [self asMat:imageBuffer];
	[self rotate:image angle:90 flip:false];
	
	if(self.overlayImage == nil)
	{
		self.overlayImage = new cv::Mat(image.rows, image.cols, CV_8UC4);
	}
	
	for (id<ImageProcessor> imageProcessor in self.pipeline)
	{
		image = [imageProcessor process:image withOverlay:*self.overlayImage];
	}
	
	[self drawOverlay];
	
	//End processing
	CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
}

-(void)drawOverlay
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
	
	NSData *data = [NSData dataWithBytes:self.overlayImage->data length:self.overlayImage->elemSize()*self.overlayImage->total()];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
	CGImage* dstImage = CGImageCreate(self.overlayImage->cols, self.overlayImage->rows, 8, 8 * self.overlayImage->elemSize(), self.overlayImage->step, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.overlay!=nil)
		{
			self.overlay.contents = (__bridge id)dstImage;
		}
	
		CGDataProviderRelease(provider);
		CGImageRelease(dstImage);
		CGColorSpaceRelease(colorSpace);
	});
}

-(cv::Mat)asMat:(CVImageBufferRef) imageBuffer
{
	int format_opencv;
	int bufferWidth;
	int bufferHeight;
	size_t bytesPerRow;
    void *bufferAddress;
	OSType format = CVPixelBufferGetPixelFormatType(imageBuffer);
	if (format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
	{
		format_opencv = CV_8UC1;
		
		bufferAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
		bufferWidth = (int)CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
		bufferHeight = (int)CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
		bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
		
	}
	else
	{
		// expect kCVPixelFormatType_32BGRA
		format_opencv = CV_8UC4;
		
		bufferAddress = CVPixelBufferGetBaseAddress(imageBuffer);
		bufferWidth = (int)CVPixelBufferGetWidth(imageBuffer);
		bufferHeight = (int)CVPixelBufferGetHeight(imageBuffer);
		bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	}
	
	cv::Mat screenImage = cv::Mat(cv::Size(bufferWidth, bufferHeight), format_opencv, bufferAddress, bytesPerRow);

	if(bufferHeight > bufferWidth)
	{
		return cv::Mat(screenImage, cv::Rect(0, (bufferHeight - bufferWidth) / 2, bufferWidth, bufferWidth));
	}
	else
	{
		return cv::Mat(screenImage, cv::Rect((bufferWidth - bufferHeight) / 2, 0, bufferHeight, bufferHeight));
	}
}

-(void) rotate:(cv::Mat) image angle:(int) angle flip:(bool) flip
{
	angle = ((angle / 90) % 4) * 90;
	
	//0 : flip vertical; 1 flip horizontal
	
	int flip_horizontal_or_vertical = angle > 0 ? 1 : 0;
	if (flip)
	{
		flip_horizontal_or_vertical = -1;
	}
	int number = abs(angle / 90);
	
	for (int i = 0; i != number; ++i)
	{
		cv::transpose(image, image);
		cv::flip(image, image, flip_horizontal_or_vertical);
	}
}

@end