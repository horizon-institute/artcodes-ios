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


#import "ACXMarkerThumbnail.h"

@interface ACXMarkerThumbnail ()
@property cv::Mat cvImage;
@property (nonatomic, retain) UIImage *uiImageColorCorrected;
@property (nonatomic, retain) UIImage *uiImageNotColorCorrected;
@end

@implementation ACXMarkerThumbnail

/**
 * Create a thumbnail image of an artcode marker that can be used in the UI.
 */
-(ACXMarkerThumbnail*)initWithContour:(int)nodeId inScene:(ACXSceneDetails*)scene atWidth:(int)width height:(int)height withColor:(UIColor*)color
{
	self = [super init];
	
	// move the colour into the opencv data type
	CGFloat red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	cv::Scalar cvColor((int)(255.0*blue),(int)(255.0*green),(int)(255.0*red),(int)(255.0*alpha));
	
	
	// work put how big our image needs to be to draw the marker while keeping the aspect ratio of the thumbnail
	cv::Rect boundingBox = cv::boundingRect(scene.contours.at(nodeId));
	double ratio = (double)width / (double)height;
	int tmpWidth=0, tmpHeight=0;
	if (boundingBox.width/ratio >= boundingBox.height)
	{
		tmpWidth = boundingBox.width;
		tmpHeight = boundingBox.width/ratio;
	}
	else
	{
		tmpWidth = boundingBox.height * ratio;
		tmpHeight = boundingBox.height;
	}
	
	// draw the marker
	cv::Mat tmp(tmpHeight, tmpWidth, CV_8UC4);
	int verticalPadding = (tmpHeight-boundingBox.height)/2;
	int horizontalPadding = (tmpWidth-boundingBox.width)/2;
	cv::drawContours(tmp, scene.contours, nodeId, cvColor, CV_FILLED, 8, scene.hierarchy, 2, cv::Point(horizontalPadding-boundingBox.tl().x,verticalPadding-boundingBox.tl().y));
	
	// resize the image to the thumbnail size
	self.cvImage = cv::Mat(height, width, CV_8UC4);
	cv::resize(tmp, self.cvImage, self.cvImage.size());
	
	return self;
}
-(cv::Mat)thumbnail
{
	return self.cvImage;
}

/**
 * For efficiency, because openCV uses an BGRA colorspace and UIImage uses RGBA, consider swaping your red and blue components when creating this ACXThumbnail and not correcting the color in this method.
 */
-(UIImage*)getUiImageWithColorCorrection:(bool)colorCorrection
{
	if (colorCorrection && self.uiImageColorCorrected != nil)
	{
		return self.uiImageColorCorrected;
	}
	else if (!colorCorrection && self.uiImageNotColorCorrected != nil)
	{
		return self.uiImageNotColorCorrected;
	}
	
	cv::Mat workingImage;
	if (colorCorrection)
	{
		workingImage = cv::Mat(self.cvImage.cols, self.cvImage.rows, self.cvImage.type());
		cvtColor( self.cvImage, workingImage, CV_BGRA2RGBA);
	}
	else
	{
		workingImage = self.cvImage;
	}
	
	NSData *data = [NSData dataWithBytes:workingImage.data length:workingImage.elemSize() * workingImage.total()];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	
	CGImageRef imageRef = CGImageCreate(workingImage.cols, workingImage.rows, 8, 8 * workingImage.elemSize(), workingImage.step[0], colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big, provider, NULL, false, kCGRenderingIntentDefault);
	
	if (colorCorrection)
	{
		self.uiImageColorCorrected = [[UIImage alloc] initWithCGImage:imageRef];
	}
	else
	{
		self.uiImageNotColorCorrected = [[UIImage alloc] initWithCGImage:imageRef];
	}
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return colorCorrection ? self.uiImageColorCorrected : self.uiImageNotColorCorrected;
}

@end
