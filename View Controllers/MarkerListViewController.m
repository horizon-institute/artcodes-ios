//
//  MarkerListViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerAction.h"
#import "MarkerSettings.h"
#import "MarkerListViewController.h"
#import "MarkerActionEditController.h"

@interface MarkerListViewController ()

@end

@implementation MarkerListViewController

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
	for (NSString* code in [MarkerSettings settings].markers)
	{
		MarkerAction* action = [[MarkerSettings settings].markers objectForKey:code];
		if(action.visible)
		{
			[markers addObject:code];
		}
	}
	
	return [markers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSArray* markers = [self getMarkerCodes];
	if([markers count] > 0 || [MarkerSettings settings].addMarkers)
	{
		if([MarkerSettings settings].editable)
		{
			return 3;
		}
		return 2;
	}
	else
	{
		if([MarkerSettings settings].editable)
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
		if([MarkerSettings settings].addMarkers)
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
	[self saveSettings];
}

-(void)saveSettings
{
	if([MarkerSettings settings].changed)
	{
		NSLog(@"Saving Settings");
		NSDictionary* dict = [[MarkerSettings settings] toDictionary];
		NSError* error = nil;
		
		NSData* json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
		
		NSURL* url = [NSURL URLWithString:@"http://www.wornchaos.org/settings.json"];
		
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEE, dd MMM yyyy hh:mm:ss zzz"];
		NSString* date = [formatter stringFromDate:[[NSDate alloc] init]];
		
		NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];
		[headers setValue:@"application/json" forKey:@"Content-Type"];
		[headers setValue:date forKey: @"Last-Modified"];
		
		NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];
		NSCachedURLResponse* cacheResponse = [[NSCachedURLResponse alloc] initWithResponse: response data: json];
		
		NSURLRequest* request = [NSURLRequest requestWithURL:url];
		
		[[NSURLCache sharedURLCache] removeAllCachedResponses];
		[[NSURLCache sharedURLCache] storeCachedResponse:cacheResponse forRequest:request];
		[MarkerSettings settings].changed = false;
	}
}

-(BOOL)shouldAutorotate
{
	return false;
}

-(void)viewWillAppear:(BOOL)animated
{
	[table reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqual:@"EditMarkerSegue"])
	{
		// Get reference to the destination view controller
        MarkerActionEditController *vc = [segue destinationViewController];
		long index = [table indexPathForCell:sender].row;
		NSString* code = [[self getMarkerCodes] objectAtIndex:index];
		vc.action = [[MarkerSettings settings].markers valueForKey:code];
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
			MarkerAction* action = [[MarkerSettings settings].markers objectForKey:code];
			cell.detailTextLabel.text = action.action;
			
			return cell;
		}
	}
	else if(indexPath.section == 1 && [MarkerSettings settings].editable)
	{
		return [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath: indexPath];
	}
	return [tableView dequeueReusableCellWithIdentifier:@"AboutCell"  forIndexPath: indexPath];
}
@end
