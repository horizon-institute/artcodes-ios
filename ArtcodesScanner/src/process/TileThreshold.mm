//
//  TileThreshold.m
//  Artcodes
//
//  Created by Kevin Glover on 20 Oct 2015.
//  Copyright © 2015 Horizon DER Institute. All rights reserved.
//

#import "TileThreshold.h"
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>

@interface TileThreshold()

@property DetectionSettings* settings;
@property int tiles;

@end

@implementation TileThreshold

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		self.settings = settings;
		return self;
	}
	return nil;
}

-(cv::Mat) process:(cv::Mat) image withOverlay:(cv::Mat) overlay
{
	cv::GaussianBlur(image, image, cv::Size(3, 3), 0);
	
	if (!self.settings.detected)
	{
		self.tiles = (self.tiles % 9) + 1;
	}
	int tileHeight = (int) image.size().height / self.tiles;
	int tileWidth = (int) image.size().width / self.tiles;
	
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
			endRow = (int) image.size().height;
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
				endCol = (int) image.size().width;
			}
			
			cv::Mat tileMat = cv::Mat(image, cv::Range(startRow, endRow), cv::Range(startCol, endCol));
			threshold(tileMat, tileMat, 127, 255, cv::THRESH_OTSU);
			tileMat.release();
		}
	}
	
	if(self.settings.displayThreshold == 0)
	{
		overlay.setTo(cv::Scalar(0, 0, 0, 0));
	}
	else
	{
		cvtColor(image,overlay,CV_GRAY2RGBA);
	}
	
	return image;
}

@end
