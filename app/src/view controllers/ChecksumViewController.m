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
#import "ChecksumViewController.h"

@interface ChecksumViewController ()

@end

@implementation ChecksumViewController

- (IBAction)valueChanged:(id)sender
{
	self.propertyLabel.text = [NSString stringWithFormat:@"%d", (int)self.propertySlider.value];
	
	self.propertyLabel.hidden = !self.enabledSwitch.on;
	self.propertySlider.hidden = !self.enabledSwitch.on;
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	self.experience.embeddedChecksum = self.embeddedSwitch.on;
	
	if(!self.enabledSwitch.on)
	{
		self.experience.checksumModulo = 1;
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

	self.embeddedSwitch.on = self.experience.embeddedChecksum;
	
	if(self.experience.checksumModulo <= 1)
	{
		self.enabledSwitch.on = false;
	}
	else
	{
		self.enabledSwitch.on = true;
		self.propertySlider.value = self.experience.checksumModulo;
	}
	
	[self valueChanged:self.propertySlider];
}
@end
