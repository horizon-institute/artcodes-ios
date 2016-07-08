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
#import "TileThreshold.h"
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

#define CHANGE_TILES_AFTER_X_EMPTY_FRAMES 5

@interface TileThreshold()

@property DetectionSettings* settings;
@property int tiles;
@property int framesSinceMarkerSeen;
@end

@implementation TileThreshold

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		self.settings = settings;
		self.framesSinceMarkerSeen = CHANGE_TILES_AFTER_X_EMPTY_FRAMES + 1;
		return self;
	}
	return nil;
}

-(void) process:(ImageBuffers*) buffers
{
	cv::GaussianBlur(buffers.image, buffers.image, cv::Size(3, 3), 0);
	
	if (self.settings.detected)
	{
		self.framesSinceMarkerSeen = 0;
	}
	else
	{
		self.framesSinceMarkerSeen += 1;
	}
	if (self.framesSinceMarkerSeen > CHANGE_TILES_AFTER_X_EMPTY_FRAMES)
	{
		self.tiles = (self.tiles % 9) + 1;
	}
	int tileHeight = (int) buffers.image.size().height / self.tiles;
	int tileWidth = (int) buffers.image.size().width / self.tiles;
	
	// Split image into tiles and apply threshold on each image tile separately.
	for (int tileRow = 0; tileRow < self.tiles; tileRow++)
	{
		int startRow = tileRow * tileHeight;
		int endRow;
		if (tileRow < self.tiles - 1)
		{
			endRow = (tileRow + 1) * tileHeight;
		}
		else
		{
			endRow = (int) buffers.image.size().height;
		}
		
		for (int tileCol = 0; tileCol < self.tiles; tileCol++)
		{
			int startCol = tileCol * tileWidth;
			int endCol;
			if (tileCol < self.tiles - 1)
			{
				endCol = (tileCol + 1) * tileWidth;
			}
			else
			{
				endCol = (int) buffers.image.size().width;
			}
			
			cv::Mat tileMat = cv::Mat(buffers.image, cv::Range(startRow, endRow), cv::Range(startCol, endCol));
			threshold(tileMat, tileMat, 127, 255, cv::THRESH_OTSU);
			tileMat.release();
		}
	}
	
	if(self.settings.displayThreshold == 0)
	{
		buffers.overlay.setTo(cv::Scalar(0, 0, 0, 0));
	}
	else
	{
		cvtColor(buffers.image,buffers.overlay,CV_GRAY2RGBA);
	}
}

@end
