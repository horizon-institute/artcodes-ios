//
//  RegionViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 13/03/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

#import "RegionViewController.h"

@interface RegionViewController ()

@end

@implementation RegionViewController

- (IBAction)regionsChanged:(id)sender
{
	int min = self.minSlider.value;
	int max = self.maxSlider.value;

	if(min > max)
	{
		if(sender == self.minSlider)
		{
			self.maxSlider.value = self.minSlider.value;
		}
		else
		{
			self.minSlider.value = self.maxSlider.value;
		}
	}
	
	
	if(min == max)
	{
		if(min == 1)
		{
			self.regionLabel.text = [NSString stringWithFormat:@"1 Region"];
		}
		else
		{
			self.regionLabel.text = [NSString stringWithFormat:@"%d Regions", min];
		}
	}
	else
	{
		self.regionLabel.text = [NSString stringWithFormat:@"%d-%d Regions", min, max];
	}
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.experience.minRegions = self.minSlider.value;
	self.experience.maxRegions = self.maxSlider.value;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.minSlider.value = self.experience.minRegions;
	self.maxSlider.value = self.experience.maxRegions;
	[self regionsChanged:self.minSlider];
}

@end
