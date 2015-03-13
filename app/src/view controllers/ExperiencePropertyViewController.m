/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
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
#import "Marker.h"
#import "Experience.h"
#import "ExperienceManager.h"
#import "ExperiencePropertyViewController.h"
#import "MarkerEditController.h"

@interface ExperiencePropertyViewController ()
@property int off;
@end

@implementation ExperiencePropertyViewController

- (IBAction)valueChanged:(id)sender
{
	self.propertyLabel.text = [NSString stringWithFormat:@"%d", (int)self.propertySlider.value];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    if([self.property isEqualToString:@"maxRegionValue"])
	{
		self.experience.maxRegionValue = self.propertySlider.value;
	}
	else if([self.property isEqualToString:@"validationRegions"])
	{
		self.experience.validationRegions = self.propertySlider.value;
	}
	else if([self.property isEqualToString:@"validationRegionValue"])
	{
		self.experience.validationRegionValue = self.propertySlider.value;
	}
	else if([self.property isEqualToString:@"checksumModulo"])
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
	
	if([self.property isEqualToString:@"maxRegionValue"])
	{
		self.propertySlider.minimumValue = 1;
		self.propertySlider.maximumValue = 20;
		self.propertySlider.value = self.experience.maxRegionValue;
	}
	else if([self.property isEqualToString:@"validationRegions"])
	{
		self.off = 0;
		self.propertySlider.minimumValue = 0;
		self.propertySlider.maximumValue = self.experience.maxRegions;
		self.propertySlider.value = self.experience.validationRegions;
	}
	else if([self.property isEqualToString:@"validationRegionValue"])
	{
		self.off = -1;
		self.propertySlider.minimumValue = 1;
		self.propertySlider.maximumValue = self.experience.maxRegionValue;
		self.propertySlider.value = self.experience.validationRegionValue;
	}
	else if([self.property isEqualToString:@"checksumModulo"])
	{
		self.off = 1;
		self.propertySlider.minimumValue = 1;
		self.propertySlider.maximumValue = 12;
		self.propertySlider.value = self.experience.checksumModulo;
	}
	
	self.title = NSLocalizedString(self.property, nil);
}
@end

