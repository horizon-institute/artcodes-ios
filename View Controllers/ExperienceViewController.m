//
//  ExperienceViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerAction.h"
#import "Experience.h"
#import "ExperienceManager.h"
#import "ExperienceViewController.h"
#import "MarkerActionEditController.h"
#import "SettingsViewController.h"

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
	for (MarkerAction* action in self.experience.markers)
	{
		if(action.visible)
		{
			[markers addObject:action.code];
		}
	}
	
	return [markers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSArray* markers = [self getMarkerCodes];
	if([markers count] > 0 || self.experience.addMarkers)
	{
		if(self.experience.editable)
		{
			return 3;
		}
		return 2;
	}
	else
	{
		if(self.experience.editable)
		{
			return 2;
		}
		return 1;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		NSArray* markers = [self getMarkerCodes];
		if(self.experience.addMarkers)
		{
			return [markers count] + 1;
		}
		else
		{
			return [markers count];
		}
	}
	else
	{
		return 1;
	}
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self saveSettings];
}

-(void)saveSettings
{
	if(self.experience.changed)
	{
		//NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		//[formatter setDateFormat:@"EEE, dd MMM yyyy hh:mm:ss zzz"];
		//self.experience.lastUpdate = [formatter stringFromDate:[[NSDate alloc] init]];
		
		[ExperienceManager save:self.experience];
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
        MarkerActionEditController *vc = [segue destinationViewController];
		long index = [table indexPathForCell:sender].row;
		NSString* code = [[self getMarkerCodes] objectAtIndex:index];
		vc.experience = self.experience;
		for(MarkerAction* action in self.experience.markers)
		{
			if([action.code isEqual:code])
			{
				vc.action = action;
			}
		}
	}
	else if([segue.identifier isEqual:@"SettingsSegue"])
	{
		SettingsViewController *vc = [segue destinationViewController];
		vc.experience = self.experience;
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
			MarkerAction* action = [self.experience getMarker:code];
			cell.detailTextLabel.text = action.action;
			
			return cell;
		}
	}
	else if(indexPath.section == 1 && self.experience.editable)
	{
		return [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath: indexPath];
	}
	return [tableView dequeueReusableCellWithIdentifier:@"AboutCell"  forIndexPath: indexPath];
}
@end
