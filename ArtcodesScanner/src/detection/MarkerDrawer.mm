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

#import "MarkerDrawer.h"
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@implementation SquareMarkerDrawer

-(cv::Mat)drawMarker:(Marker*)marker contours:(cv::vector<cv::vector<cv::Point> >&)contours hierarchy:(cv::vector<cv::Vec4i>&)hierarchy boundingRect:(cv::Rect&)boundingRect
{
	cv::Scalar BACKGROUND = cv::Scalar(0,0,0,0);
	cv::Scalar COLOR = cv::Scalar(255,255,255,255);
	
	int size = MAX(boundingRect.height, boundingRect.width);
	int offsetX = (size - boundingRect.width) / 2;
	int offsetY = (size - boundingRect.height) / 2;
	cv::Mat output = cv::Mat(size, size, CV_8UC4, BACKGROUND);
	
	cv::drawContours(output, contours, (int) marker.index, COLOR, -1, 8, hierarchy, 2, cv::Point(offsetX-boundingRect.tl().x, offsetY-boundingRect.tl().y));
	
	return output;
}

-(MarkerImage*)drawMarker:(Marker*)marker scene:(SceneDetails*)scene
{
	cv::Rect boundingBox = cv::boundingRect(scene.contours->at(marker.index));
	cv::Mat mat = [self drawMarker:marker contours:*scene.contours hierarchy:*scene.hierarchy boundingRect:boundingBox];
	UIImage* uiImage = [SquareMarkerDrawer UIImageFromCVMat:mat];
	
	float x = boundingBox.x, y = boundingBox.y;
	// if boundingBox was not a square x,y to return will be different
	if (boundingBox.width<boundingBox.height)
	{
		x = x - (mat.cols - boundingBox.width) / 2.0;
	}
	else if (boundingBox.width>boundingBox.height)
	{
		y = y - (mat.rows - boundingBox.height) / 2.0;
	}
	
	return [[MarkerImage alloc]
			initWithCode: marker.description
			image: uiImage
			x: x/scene.sourceImageSize.width
			y: y/scene.sourceImageSize.height
			width:	(float)mat.cols/(float)scene.sourceImageSize.width
			height: (float)mat.rows/(float)scene.sourceImageSize.height];
}

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
	NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
	CGColorSpaceRef colorSpace;
	
	if (cvMat.elemSize() == 1)
	{
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaFirst | kCGBitmapByteOrder32Little, provider, NULL, false, kCGRenderingIntentDefault);
	UIImage* resultImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return resultImage;
}

@end
