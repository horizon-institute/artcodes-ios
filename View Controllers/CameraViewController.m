//
//  ACFirstViewController.m
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "CameraViewController.h"
#import "MarkerSelection.h"
#import "Marker.h"
#import "MarkerSettings.h"
#import "MarkerAction.h"
#import "MarkerActionViewController.h"

@interface CameraViewController ()
@property MarkerSelection* markerSelection;
@property MarkerCamera* camera;

-(void)loadSettingsData:(NSData*)data;
@end

@implementation CameraViewController

@synthesize camera;
@synthesize markerSelection;


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self loadSettings];
	camera = [[MarkerCamera alloc] init];
	markerSelection = [[MarkerSelection  alloc] init];
	
	//modeSelection.dataSource = self;
}

-(void)viewDidAppear:(BOOL)animated
{
	camera.markerDelegate = self;
	[camera start:self.imageView];
}


-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBarHidden = false;
	
	[camera stop];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.navigationController.navigationBarHidden = true;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [camera stop];
}

#pragma mark - Protocol CvVideoCameraDelegate

-(void)loadSettings
{
	// Load in local settings file while loading url
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"json"];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	[self loadSettingsData: data];
	
	NSURL *URL = [NSURL URLWithString:[MarkerSettings settings].updateURL];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *task = [session dataTaskWithRequest:request
											completionHandler:
								  ^(NSData *data, NSURLResponse *response, NSError *error) {
									  dispatch_async(dispatch_get_main_queue(), ^{
										  [self loadSettingsData: data];
									  });
								  }];
	
	[task resume];
}

-(void)loadSettingsData:(NSData*) data
{
	NSError* error;
	NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
	
	if (! json)
	{
		NSLog(@"Got an error: %@", error);
	}
	else
	{
		[[MarkerSettings settings] load:json];
	}
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	// Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"MarkerActionSegue"])
    {
        // Get reference to the destination view controller
        MarkerActionViewController *vc = [segue destinationViewController];
		vc.action = sender;
    }
}

-(IBAction)segmentChange:(id)sender
{
	UISegmentedControl* control = sender;
	camera.drawMode = control.selectedSegmentIndex;
}


-(UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)markersFound:(NSDictionary*)markers
{
	[markerSelection addMarkers:markers];

	dispatch_async(dispatch_get_main_queue(), ^{
		if([markerSelection hasTimedOut])
		{
			[self.progressView setHidden:true];
		}
		else if([markerSelection hasStarted])
		{
			[self.progressView setProgress: [markerSelection getProgress]];
			[self.progressView setHidden:false];
			[self.progressView setAlpha:1 - [markerSelection getTimeOutProgress]];
		}
	});

	if([markerSelection hasTimedOut])
	{
		[markerSelection reset];
	}
	else if([markerSelection hasFinished])
	{
		Marker* marker = [markerSelection getSelected];
		MarkerAction* markerAction = [[[MarkerSettings settings] markers] valueForKey:[marker codeKey]];
		NSLog(@"Marker found: %@", marker.codeKey);
		if (markerAction)
		{
			NSLog(@"Action found: %@", markerAction.code);
			[markerSelection reset];
			[camera stop];
			if ([markerAction showDetail])
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self performSegueWithIdentifier:@"MarkerActionSegue" sender:markerAction];
				});
			}
			else
			{
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[markerAction action]]];
			}
		}
	}
}
@end