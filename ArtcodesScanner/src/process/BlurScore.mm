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

#import "ImageBuffers.h"
#import "BlurScore.h"
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

/*
 Based on Pech-Pacheco et al. “Diatom autofocusing in brightfield
 microscopy: a comparative study” (https://doi.org/10.1109/ICPR.2000.903548)
 and blog post
 https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/,
 it evaluates how blurry the image is and then re-focuses the camera if
 required.
 */

@interface BlurScore()

@property (weak, nonatomic) id<FocusCallback> focusClosure;

@end

@implementation BlurScore

-(bool) requiresBgraInput
{
	return false;
}

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		return self;
	}
	return nil;
}

-(id)initWithFocusClosure:(id<FocusCallback>) focusClosure
{
	if (self = [super init])
	{
		self.focusClosure = focusClosure;
		return self;
	}
	return nil;
}

-(void) process:(ImageBuffers*) buffers
{
	
	// ImageBuffers implements this if needed when switching to the grey scale color space from
	// either RGB or YUV.
	cv::Mat greyImage = [buffers imageInGrey];
	
	// get center of image
	int roiSize = MIN(greyImage.rows, greyImage.cols)/2;
	cv::Mat subMat(greyImage, cv::Rect((greyImage.cols-roiSize)/2,(greyImage.rows-roiSize)/2,roiSize,roiSize));
	cv::Mat dst;
	
	cv::Laplacian(subMat, dst, CV_16S);
	
	cv::Mat mean;
	cv::Mat stdDev;
	cv::meanStdDev(dst, mean, stdDev);
	
	cv::Mat overlay = [buffers overlay];
	
	double score = pow(stdDev.at<double>(0),2);
	NSLog(@"b.score: %d", (int)score);
	if (score <= 100)
	{
		NSLog(@"Focusing on center");
		[self.focusClosure focusOnCenter];
	}
}

@end
