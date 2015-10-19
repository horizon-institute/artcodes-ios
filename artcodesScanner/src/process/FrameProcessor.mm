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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import "FrameProcessor.h"
#include <vector>
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/ios.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@interface FrameProcessor()

@property (nonatomic) cv::Mat* overlayImage;
@property BOOL detected;
@end

@implementation FrameProcessor


- ( void ) captureOutput: ( AVCaptureOutput * ) captureOutput
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

	[self thresholdImage:image];
	if (self.displayThreshold == 1)
	{
		cvtColor(image,*self.overlayImage,CV_GRAY2RGBA);
	}
	else if(self.displayThreshold == 0)
	{
		self.overlayImage->setTo(cv::Scalar(0, 0, 0, 0));
	}
	
	// find contours:
	std::vector<std::vector<cv::Point> > contours;
	std::vector<cv::Vec4i> hierarchy;
	cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	if (self.displayThreshold == 2)
	{
		cvtColor(image,*self.overlayImage,CV_GRAY2RGBA);
	}
	
	// This autoreleasepool prevents memory allocated in [self findMarkers] from leaking.
	@autoreleasepool{
		//detect markers
		NSArray* markers = [self findMarkers:hierarchy andImageContour:contours];
		
		self.detected = markers.count > 0;		
		if(self.markerCallback != nil)
		{
			self.markerCallback(markers);
		}
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

-(void)drawMarker:(NSString*)marker atIndex:(int)index withContours:(cv::vector<cv::vector<cv::Point> >)contours andHierarchy:(cv::vector<cv::Vec4i>)hierarchy
{
	//color to draw contours
	cv::Scalar markerColor = cv::Scalar(0, 255, 255, 255);
	cv::Scalar regionColor = cv::Scalar(0, 128, 255, 255);
	cv::Scalar outlineColor = cv::Scalar(0, 0, 0, 255);

	if(self.displayOutline > 0)
	{
		cv::Vec4i nodes = hierarchy.at(index);
		int currentRegionIndex= nodes[CHILD_NODE_INDEX];
		// Loop through the regions, verifing the value of each:
		if(self.displayOutline == 2)
		{
			while (currentRegionIndex >= 0)
			{
				cv::drawContours(*self.overlayImage, contours, currentRegionIndex, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
				cv::drawContours(*self.overlayImage, contours, currentRegionIndex, regionColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
			
				// Get next region:
				nodes = hierarchy.at(currentRegionIndex);
				currentRegionIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
		}
		
		cv::drawContours(*self.overlayImage, contours, index, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
		cv::drawContours(*self.overlayImage, contours, index, markerColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
	}

	// draw code:
	if(self.displayText == 1)
	{
		cv::Rect markerBounds = boundingRect(contours[index]);
		markerBounds.x = markerBounds.x;
		markerBounds.y = markerBounds.y;
			
		cv::putText(*self.overlayImage, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(*self.overlayImage, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
	}
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

int tiles=1;
-(void) thresholdImage:(cv::Mat) image
{
	cv::GaussianBlur(image, image, cv::Size(3, 3), 0);
			
	if (!self.detected)
	{
		tiles = (tiles % 9) + 1;
	}
	int tileHeight = (int) image.size().height / tiles;
	int tileWidth = (int) image.size().width / tiles;
	
	// Split image into tiles and apply threshold on each image tile separately.
	for (int tileRow = 0; tileRow < tiles; tileRow++)
	{
		int startRow = tileRow * tileHeight;
		int endRow;
		if (tileRow < tiles - 1)
		{
			endRow = (tileRow + 1) * tileHeight;
		}
		else
		{
			endRow = (int) image.size().height;
		}
				
		for (int tileCol = 0; tileCol < tiles; tileCol++)
		{
			int startCol = tileCol * tileWidth;
			int endCol;
			if (tileCol < tiles - 1)
			{
				endCol = (tileCol + 1) * tileWidth;
			}
			else
			{
				endCol = (int) image.size().width;
			}
					
			cv::Mat tileMat(image, cv::Range(startRow, endRow), cv::Range(startCol, endCol));
			threshold(tileMat, tileMat, 127, 255, cv::THRESH_OTSU);
			tileMat.release();
		}
	}
}

-(NSArray*)findMarkers:(std::vector<cv::Vec4i>)hierarchy andImageContour:(std::vector<std::vector<cv::Point> >)contours
{
	/*! Detected markers */
	NSMutableArray* markers = [[NSMutableArray alloc] init];
	//int skippedContours = 0;
	
	//NSLog(@"Contours %lu", contours.size());
	for (int i = 0; i < contours.size(); i++)
	{
		//if (contours[i].size() < self.cameraSettings.minimumContourSize)
		//{
		//	++skippedContours;
		//	continue;
		//}
		
		NSArray* markerCode = [self createMarkerForNode:i imageHierarchy:hierarchy];
		if (markerCode != nil)
		{
			NSString* markerKey = [self getCodeKey:markerCode];
			if([self.settings.validCodes containsObject:markerKey])
			{
				[markers addObject: markerKey];
			
				[self drawMarker:markerKey atIndex:i withContours:contours andHierarchy:hierarchy];
			}
		}
	}
	
	//NSLog(@"Skipped contours: %d/%lu",skippedContours,contours.size());
	return markers;
}

-(NSString*)getCodeKey:(NSArray*)code
{
	NSMutableString* codeStr;
	
	for (int i =0; i < code.count; i++)
	{
		if (i > 0)
		{
			[codeStr appendFormat:@":%ld", (long)[[code objectAtIndex:i] integerValue]];
		}
		else
		{
			codeStr = [[NSMutableString alloc] init];
			[codeStr appendFormat:@"%ld", (long)[[code objectAtIndex:i] integerValue]];
		}
	}
	
	return codeStr;
}

const static int CHILD_NODE_INDEX = 2;
const static int NEXT_SIBLING_NODE_INDEX = 0;
const static int REGION_INVALID = -1;
const static int REGION_EMPTY = 0;

-(NSArray*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	int currentRegionIndex = imageHierarchy.at(nodeIndex)[CHILD_NODE_INDEX];
	if (currentRegionIndex < 0)
	{
		//NSLog(@"No regions");
		return nil; // There are no regions.
	}
	
	int numOfRegions = 0;
	int numOfEmptyRegions = 0;
	NSMutableArray* markerCode = nil;
	NSNumber* embeddedChecksumValue = nil;
	
	// Loop through the regions, verifing the value of each:
	for (; currentRegionIndex >= 0; currentRegionIndex = imageHierarchy.at(currentRegionIndex)[NEXT_SIBLING_NODE_INDEX])
	{
		int regionValue = [self getRegionValueForRegionAtIndex:currentRegionIndex inImageHierarchy:imageHierarchy];
		if (regionValue == REGION_EMPTY)
		{
			//NSLog(@"Empty region: %@",markerCode);
			return nil;
		}
		
		if (regionValue == REGION_INVALID)
		{
			// Not a normal region, so look for embedded checksum:
			if (self.settings.embeddedChecksum && embeddedChecksumValue == nil) // if we've not found it yet:
			{
				embeddedChecksumValue = [self getEmbeddedChecksumValueForRegionAtIndex:currentRegionIndex inImageHierarchy:imageHierarchy];
				if (embeddedChecksumValue != nil)
				{
					continue; // this is a checksum region, so continue looking for regions
				}
			}
			
			//NSLog(@"Too many levels: %@",markerCode);
			return nil; // Too many levels.
		}
		
		if(++numOfRegions > self.settings.maxRegions)
		{
			//NSLog(@"Too many regions: %@",markerCode);
			return nil; // Too many regions.
		}
		
		// Add region value to code:
		if (markerCode == nil)
		{
			markerCode = [[NSMutableArray alloc] initWithObjects:@(regionValue), nil];
		}
		else
		{
			[markerCode addObject:@(regionValue)];
		}
	}
	
	// Marker should have at least one non-empty branch. If all branches are empty then return false.
	if ((numOfRegions - numOfEmptyRegions) < 1)
	{
		//NSLog(@"Empty regions: %@",markerCode);
		return nil;
	}
	
	// sort the code (the order may effect embedded checksum)
	NSArray* sortedMarkerCode = [markerCode sortedArrayUsingSelector: @selector(compare:)];
	if ([self.settings isValid:sortedMarkerCode withEmbeddedChecksum:embeddedChecksumValue])
	{
		return sortedMarkerCode;
	}
	return nil;
}

-(int)getRegionValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return REGION_EMPTY; // There are no dots.
	}
	
	// Count all the dots and check if they are leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidLeaf:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get the next dot index:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			
			if (dotCount > self.settings.maxRegionValue)
			{
				return REGION_INVALID; // Too many dots.
			}
		}
		else
		{
			return REGION_INVALID; // Dot is not a leaf.
		}
	}
	
	return dotCount;
}

-(bool)isValidLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] < 0;
}

-(NSNumber*)getEmbeddedChecksumValueForRegionAtIndex:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0)
	{
		return nil; // There are no dots.
	}
	
	// Count all the dots and check if they are double-leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidDoubleLeaf:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get the next dot index:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
		}
		else
		{
			return nil; // Wrong number of levels.
		}
	}
	
	return @(dotCount);
}

-(bool)isValidDoubleLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] >= 0 && // has a child node, and
	imageHierarchy.at(nodes[CHILD_NODE_INDEX])[NEXT_SIBLING_NODE_INDEX] < 0 && //the child has no siblings, and
	[self isValidLeaf:nodes[CHILD_NODE_INDEX] inImageHierarchy:imageHierarchy];// the child is a leaf
}

@end