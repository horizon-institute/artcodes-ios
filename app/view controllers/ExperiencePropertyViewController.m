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
@property int min;
@property int max;
@property int off;
@property int value;
@end

@implementation ExperiencePropertyViewController

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.max - self.min + 1;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.value = (int)indexPath.row + self.min;
	[tableView reloadData];
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    if([self.property isEqualToString:@"minRegions"])
    {
        self.experience.minRegions = self.value;
    }
    else if([self.property isEqualToString:@"maxRegions"])
    {
        self.experience.maxRegions = self.value;
    }
    else if([self.property isEqualToString:@"maxRegionValue"])
	{
		self.experience.maxRegionValue = self.value;
	}
	else if([self.property isEqualToString:@"validationRegions"])
	{
		self.experience.validationRegions = self.value;
	}
	else if([self.property isEqualToString:@"validationRegionValue"])
	{
		self.experience.validationRegionValue = self.value;
	}
	else if([self.property isEqualToString:@"checksumModulo"])
	{
		self.experience.checksumModulo = self.value;
	}
}

-(BOOL)shouldAutorotate
{
	return false;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[table reloadData];
	
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	
	if([self.property isEqualToString:@"minRegions"])
	{
		self.min = 1;
		self.max = self.experience.maxRegions;
		self.off = -1;
		self.value = self.experience.minRegions;
	}
	else if([self.property isEqualToString:@"maxRegions"])
	{
		self.min = self.experience.minRegions;
		self.max = 20;
		self.off = -1;
		self.value = self.experience.maxRegions;
	}
	else if([self.property isEqualToString:@"maxRegionValue"])
	{
		self.min = 1;
		self.max = 20;
		self.off = -1;
		self.value = self.experience.maxRegionValue;
	}
	else if([self.property isEqualToString:@"validationRegions"])
	{
		self.off = 0;
		self.min = 0;
		self.max = self.experience.maxRegions;
		self.value = self.experience.validationRegions;
	}
	else if([self.property isEqualToString:@"validationRegionValue"])
	{
		self.min = 1;
		self.max = self.experience.maxRegionValue;
		self.off = -1;
		self.value = self.experience.validationRegionValue;
	}
	else if([self.property isEqualToString:@"checksumModulo"])
	{
		self.off = 1;
		self.min = 1;
		self.max = 12;
		self.value = self.experience.checksumModulo;
	}
	
	self.title = NSLocalizedString(self.property, nil);
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PropertyValueCell" forIndexPath: indexPath];
	
	int cellValue = (int)indexPath.row + self.min;
	if(cellValue == self.value)
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	if(cellValue == self.off)
	{
		NSString* off = [NSString stringWithFormat:@"%@_off", self.property];
		[cell.textLabel setText: NSLocalizedString(off, nil)];
	}
	else
	{
		[cell.textLabel setText:[NSString stringWithFormat:@"%d", (int)(indexPath.row + self.min)]];
	}
	
	return cell;
}
@end

