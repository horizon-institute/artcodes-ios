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
#import "OtsuThreshold.h"
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>


@implementation OtsuThresholdFactory

-(NSString*) name
{
	return @"OTSU";
}

-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[OtsuThreshold alloc] initWithSettings:settings];
}

@end


@interface OtsuThreshold()

@property DetectionSettings* settings;
@property int tiles;
@end

@implementation OtsuThreshold

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		self.settings = settings;
		return self;
	}
	return nil;
}

-(bool) requiresBgraInput
{
	return false;
}

-(void) process:(ImageBuffers*) buffers
{
	cv::Mat image = [buffers imageInGrey];
	cv::GaussianBlur(image, image, cv::Size(3, 3), 0);
	threshold(image, image, 127, 255, cv::THRESH_OTSU);
	
	if(self.settings.displayThreshold == 0)
	{
		[buffers clearOverlay];
	}
	else
	{
		cvtColor(image, buffers.overlay,CV_GRAY2RGBA);
	}
}

@end
