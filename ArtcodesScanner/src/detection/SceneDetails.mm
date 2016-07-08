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

#import "SceneDetails.h"

@implementation ImageSize

-(ImageSize*)initWithMat:(cv::Mat const&)mat
{
	if (self = [super init])
	{
		self.width = mat.cols;
		self.height = mat.rows;
	}
	return self;
}

@end

@implementation SceneDetails

-(SceneDetails*)initWithContours:(cv::vector<cv::vector<cv::Point> >&)contours hierarchy:(cv::vector<cv::Vec4i>&)hierarchy sourceImageSize:(ImageSize*)sourceImageSize
{
	if (self = [super init])
	{
		self.contours = &contours;
		self.hierarchy = &hierarchy;
		self.sourceImageSize = sourceImageSize;
	}
	return self;
}
@end
