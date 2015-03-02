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
#import "ExperienceViewController.h"
#import "MarkerEditController.h"

@interface ExperienceViewController ()

@end

@implementation ExperienceViewController

- (id)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Uncomment the following line to preserve selection between presentations.
	// self.clearsSelectionOnViewWillAppear = NO;
	
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(NSArray*) getMarkerCodes
{
	NSMutableArray* markers = [[NSMutableArray alloc] init];
	for (Marker* action in self.experience.markers)
	{
		[markers addObject:action.code];
	}
	
	return [markers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
	//	NSArray* markers = [self getMarkerCodes];
	//	if([markers count] > 0 || self.experience.addMarkers)
	//	{
	//		if(self.experience.editable)
	//		{
	//			return 3;
	//		}
	//		return 2;
	//	}
	//	else
	//	{
	//		if(self.experience.editable)
	//		{
	//			return 2;
	//		}
	//		return 1;
	//	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		NSArray* markers = [self getMarkerCodes];
		return [markers count] + 1;
	}
	else
	{
		return 1;
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
	self.title = [NSString stringWithFormat:@"%@ Markers", self.experience.name];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqual:@"EditMarkerSegue"])
	{
		// Get reference to the destination view controller
		MarkerEditController *vc = [segue destinationViewController];
		long index = [table indexPathForCell:sender].row;
		NSString* code = [[self getMarkerCodes] objectAtIndex:index];
		vc.experience = self.experience;
		for(Marker* action in self.experience.markers)
		{
			if([action.code isEqual:code])
			{
				vc.marker = action;
			}
		}
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* markerCodes = [self getMarkerCodes];
	if(indexPath.section == 0)
	{
		if(indexPath.row >= markerCodes.count)
		{
			return [tableView dequeueReusableCellWithIdentifier:@"AddMarkerCell" forIndexPath:indexPath];
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EditMarkerCell" forIndexPath: indexPath];
			
			NSString* code = [markerCodes objectAtIndex:indexPath.row];
			cell.textLabel.text = [NSString stringWithFormat:@"Marker %@", code];
			Marker* action = [self.experience getMarker:code];
			cell.detailTextLabel.text = action.action;
			
			return cell;
		}
	}
	//	else if(indexPath.section == 1 && self.experience.editable)
	//	{
	//		return [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath: indexPath];
	//	}
	//	return [tableView dequeueReusableCellWithIdentifier:@"AboutCell"  forIndexPath: indexPath];
	return nil;
}
@end

