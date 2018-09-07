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
#import "ImageBuffers.h"
#import "ImageProcessorRegistory.h"
#import "TileThreshold.h"
#import "MarkerDetector.h"
#import <artcodesScanner/artcodesScanner-Swift.h>
#import "BlurScore.h"


@interface FrameProcessor()

@property ImageBuffers* buffers;
@property DetectionSettings* settings;
@property bool isFocusing;

@property id<ScreenshotHandler> screenshotHandler;

@end

@implementation FrameProcessor

-(void) createPipeline:(NSArray *)pipeline andSettings:(DetectionSettings*) settings
{
	self.fullscreen = [settings.experience isFullscreen];
	
	NSMutableArray<ImageProcessor>* newPipeline = [[NSMutableArray<ImageProcessor> alloc] init];
	
	bool missingProcessors = false;
	
	ImageProcessorRegistory* imageProcessorRegistory = [ImageProcessorRegistory sharedInstance];
	
	if (settings.experience.requestedAutoFocusMode != nil && [settings.experience.requestedAutoFocusMode isEqualToString:@"blurScore"])
	{
		id<ImageProcessor> imageProcessor = [[BlurScore alloc] initWithFocusClosure:self.focusCallback];
		[newPipeline addObject:imageProcessor];
	}
	
	for(NSString* pipelineString in pipeline)
	{
		id<ImageProcessor> imageProcessor = [imageProcessorRegistory getProcessorForString:pipelineString WithSettings:settings];
		NSLog(@"imageProcessorRegistory input: %@ output: %@", pipelineString, imageProcessor);
		
		if (imageProcessor != nil)
		{
			[newPipeline addObject:imageProcessor];
		}
		else
		{
			missingProcessors = true;
		}
	}
	
	if (missingProcessors)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hmm..."
														message:@"This experience may use features not available in this version of Artcodes. It might work fine but you can check the AppStore for updates."
													   delegate:self
											  cancelButtonTitle:@"Continue"
											  otherButtonTitles:@"Update", nil];
		[alert show];
	}
	
	if ([newPipeline count]==0)
	{
		// No pipeline supplied, use defaults:
		[newPipeline addObject:[[TileThreshold alloc] initWithSettings:settings]];
		[newPipeline addObject:[[MarkerDetector alloc] initWithSettings:settings]];
	}
	
	self.buffers = [[ImageBuffers alloc] init];
	
	self.pipeline = newPipeline;
	self.settings = settings;
}

-(void) captureOutput: ( AVCaptureOutput * ) captureOutput
	didOutputSampleBuffer: ( CMSampleBufferRef ) sampleBuffer
	fromConnection: ( AVCaptureConnection * ) connection
{
	if (!self.isFocusing)
	{
		// setup saving images
		cv::Mat ** savedMats = nil;
		const int numberOfSavedImages = (int) [self.pipeline count] + 1;
		int savedMatsIndex = 0;
		id<ScreenshotHandler> screenshotHandler = self.screenshotHandler;
		if (screenshotHandler != nil)
		{
			// taken local copy of screenshot handler and remove reference in class
			self.screenshotHandler = nil;
			savedMats = new cv::Mat*[numberOfSavedImages];
		}
		
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		
		CVPixelBufferLockBaseAddress( imageBuffer, 0 );
		
		[self.buffers setNewFrame:[self asMat:imageBuffer]];
		
		if (savedMats != nil)
		{
			savedMats[savedMatsIndex] = new cv::Mat();
			[self.buffers imageInBgr].copyTo(*savedMats[savedMatsIndex++]);
		}
		
		for (id<ImageProcessor> imageProcessor in self.pipeline)
		{
			[imageProcessor process:self.buffers];
			if (savedMats != nil)
			{
				savedMats[savedMatsIndex] = new cv::Mat();
				[self.buffers imageInBgr].copyTo(*savedMats[savedMatsIndex++]);
			}
		}

		[self drawOverlay];
		
		//End processing
		CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
		
		
		if (savedMats != nil)
		{
			// convert OpenCV Mats to UIImages
			NSMutableArray<UIImage*> * screenshots = [[NSMutableArray alloc] init];
			for (int i=0; i<numberOfSavedImages; ++i)
			{
				[screenshots addObject: [self getUIImageForMat:savedMats[i]]];
			}
			if (self.buffers.hasOverlay)
			{
				cv::Mat * o = new cv::Mat(self.buffers.overlay);
				[screenshots addObject: [self getUIImageForMat:o]];
				delete o;
			}
			
			[screenshotHandler handleScreenshots:screenshots];
			
			AudioServicesPlaySystemSound(1108);
			
			// clean up saved Mats
			for (int i=0; i<numberOfSavedImages; ++i)
			{
				delete savedMats[i];
			}
			delete[] savedMats;
		}
	}
}

-(void)drawOverlay
{
	if(self.overlay != nil)
	{
		if(self.buffers.hasOverlay)
		{
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
			
			NSData *data = [NSData dataWithBytes:self.buffers.overlay.data length:self.buffers.overlay.elemSize()*self.buffers.overlay.total()];
			CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
			
			CGImage* dstImage = CGImageCreate(self.buffers.overlay.cols, self.buffers.overlay.rows, 8, 8 * self.buffers.overlay.elemSize(), self.buffers.overlay.step, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
			
			CGDataProviderRelease(provider);
			CGColorSpaceRelease(colorSpace);
			dispatch_async(dispatch_get_main_queue(), ^{
				self.overlay.contents = (__bridge id)dstImage;
				
				CGImageRelease(dstImage);
			});
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				self.overlay.contents = nil;
			});
		}
	}
}

-(UIImage*)getUIImageForMat:(const cv::Mat*)image
{
	CGColorSpaceRef colorSpace = image->channels()==1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = (image->channels()==4 ? kCGImageAlphaFirst : kCGImageAlphaNone) | kCGBitmapByteOrder32Little;
	
	NSData *data = [NSData dataWithBytes:image->data length:image->elemSize()*image->total()];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	
	CGImage* cgImage = CGImageCreate(image->cols, image->rows, 8, 8 * image->elemSize(), image->step, colorSpace, bitmapInfo, provider, NULL, false, kCGRenderingIntentDefault);
	
	UIImage *uiImage = [UIImage imageWithData:UIImagePNGRepresentation([[UIImage alloc] initWithCGImage:cgImage])];
	
	// COMMENT THIS WHEN MAKING LIB FOR CORDOVA PLUGIN
	UIImageWriteToSavedPhotosAlbum(uiImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
	
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	CGImageRelease(cgImage);
	
	return uiImage;
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
	cv::Mat result;
	
	if (self.fullscreen)
	{
		result = screenImage;
	}
	else if(bufferHeight > bufferWidth)
	{
		result = cv::Mat(screenImage, cv::Rect(0, (bufferHeight - bufferWidth) / 2, bufferWidth, bufferWidth));
	}
	else
	{
		result = cv::Mat(screenImage, cv::Rect((bufferWidth - bufferHeight) / 2, 0, bufferHeight, bufferHeight));
	}
	
	// Rotate 90
	cv::transpose(result, result);
	cv:flip(result, result, 1);
	return result;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		// Go to AppStore
		// TODO This shouldn't be hardcoded
		NSString *iTunesLink = @"https://itunes.apple.com/app/artcodes/id703429621";
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];

	}
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
 
	if ([keyPath isEqualToString:@"adjustingFocus"]) {
		self.isFocusing = [change[@"new"] boolValue];
	}
 
}

-(void) takeScreenshots:(id<ScreenshotHandler>)screenshotHandler
{
	self.screenshotHandler = screenshotHandler;
}

@end
