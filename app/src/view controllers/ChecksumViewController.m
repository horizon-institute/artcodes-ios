//
//  ChecksumViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 16/03/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

#import "ChecksumViewController.h"

@interface ChecksumViewController ()

@end

@implementation ChecksumViewController

- (IBAction)valueChanged:(id)sender
{
	self.propertyLabel.text = [NSString stringWithFormat:@"%d", (int)self.propertySlider.value];
	
	if(self.enabledSwitch.on)
	{
		self.embeddedSwitch.hidden = false;
		self.embeddedLabel.hidden = false;
		if(self.embeddedSwitch.on)
		{
			self.propertyLabel.hidden = true;
			self.propertySlider.hidden = true;
		}
		else
		{
			self.propertyLabel.hidden = false;
			self.propertySlider.hidden = false;
		}
	}
	else
	{
		self.embeddedSwitch.hidden = true;
		self.embeddedLabel.hidden = true;
		self.propertyLabel.hidden = true;
		self.propertySlider.hidden = true;
	}
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	if(!self.enabledSwitch.on)
	{
		self.experience.checksumModulo = 1;
	}
	else if(self.embeddedSwitch.on)
	{
		self.experience.checksumModulo = -1;
	}
	else
	{
		self.experience.checksumModulo = self.propertySlider.value;
	}
}

-(BOOL)shouldAutorotate
{
	return false;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if(self.experience.checksumModulo == -1)
	{
		self.enabledSwitch.on = true;
		self.embeddedSwitch.on = true;
	}
	else if(self.experience.checksumModulo <= 1)
	{
		self.enabledSwitch.on = false;
	}
	else
	{
		self.enabledSwitch.on = true;
		self.embeddedSwitch.on = false;
		self.propertySlider.value = self.experience.checksumModulo;
	}
	[self valueChanged:self.propertySlider];
}
@end