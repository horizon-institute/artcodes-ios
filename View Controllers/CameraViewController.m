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
#import "Experience.h"
#import "MarkerAction.h"
#import "SlidingViewController.h"
#import "MarkerActionViewController.h"
#import "ExperienceListViewController.h"
#import "AKPickerView.h"

@interface CameraViewController ()
@property MarkerSelection* markerSelection;
@property MarkerCamera* camera;
@property UILabel* experienceLabel;

@end

@implementation CameraViewController

@synthesize experienceLabel;
@synthesize camera;
@synthesize modePicker;
@synthesize modeSelectionMark;
@synthesize markerSelection;


-(void)viewDidLoad
{
    [super viewDidLoad];

	self.experienceLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 150, 20)];
	[self.experienceLabel setFont:[UIFont fontWithName:@"Helvetica-Neue" size:16]];
	[self.experienceLabel setBackgroundColor:[UIColor clearColor]];
	[self.experienceLabel setTextColor:[UIColor whiteColor]];
	
	NSMutableArray *newItems = [self.toolbar.items mutableCopy];
	UIBarButtonItem *labelItem = [[UIBarButtonItem alloc] initWithCustomView:experienceLabel];
	[newItems insertObject:labelItem atIndex:0];
	[self.toolbar setItems:newItems];
	
	self.experienceManager = [[ExperienceManager alloc] init];
	self.experienceManager.delegate = self;
	[self.experienceManager load];
	
	camera = [[MarkerCamera alloc] init];
	camera.experienceManager = self.experienceManager;
	markerSelection = [[MarkerSelection  alloc] init];
}

-(void)experienceChanged:(Experience *)experience
{
	[self.experienceLabel setText:self.experienceManager.selected.name];
	[modePicker reloadData];
	if([self.experienceManager.selected.modes count] <= 1)
	{
		modePicker.hidden = true;
		modeSelectionMark.hidden = true;
		if([self.experienceManager.selected.modes count] == 1)
		{
			camera.mode = [self.experienceManager.selected.modes objectAtIndex:0];
		}
		else
		{
			camera.mode = @"detect";
		}
	}
	else
	{
		modePicker.hidden = false;
		modeSelectionMark.hidden = false;
		if(camera.mode != nil)
		{
			
		}
		else
		{
			[modePicker selectItem:0 animated:false];
		}
	}
	
	[self experiencesChanged];
}

-(void)experiencesChanged
{
	if([self.slidingViewController.underRightViewController isKindOfClass:[ExperienceListViewController class]])
	{
		ExperienceListViewController* controller = (ExperienceListViewController*)self.slidingViewController.underRightViewController;
		controller.experienceManager = self.experienceManager;
		[controller.tableView reloadData];
		
		NSUInteger index = [self.experienceManager.experiences indexOfObject:self.experienceManager.selected];
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		[controller.tableView selectRowAtIndexPath:indexPath animated:false scrollPosition:UITableViewScrollPositionNone];
	}
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"View did appear.");
	[super viewDidAppear:animated];
	[camera start:self.imageView];
	
	self.barLeft.hidden = camera.fullSizeViewFinder;
	self.barRight.hidden = camera.fullSizeViewFinder;
	
	if (camera.raisedTopBorder)
	{
		// find the constrain that specifies height:
		for (NSLayoutConstraint * constraint in [self.barTop constraints])
		{
			if ([constraint firstAttribute] == NSLayoutAttributeHeight)
			{
				// change it to a smaller value:
				constraint.constant = 60;
				break;
			}
		}
	}
	// If the device doesn't have a front camera disable the camera switch button
	self.flipButton.enabled = [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront];
		
    // Ask the system to notify us when in forground: (removed in [self prepareForSegue])
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

/*!
 Called when the system tells us the app is in the forground
 */
- (void)applicationEnteredForeground:(NSNotification *)notification
{
    [camera start:self.imageView];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBarHidden = false;
	
	[camera stop];
}

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
	return [self.experienceManager.selected.modes count];
}

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item;
{
	[self.markerSelection reset];
	[self.progressView setHidden:true];
	return NSLocalizedString([self.experienceManager.selected.modes objectAtIndex:item], nil);
}

- (IBAction)flipCamera:(UIBarButtonItem *)sender
{
	[camera flip:self.imageView];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.navigationController.navigationBarHidden = true;
	
	modePicker.delegate = self;
	modePicker.font = [UIFont systemFontOfSize:16];
	modePicker.textColor = [UIColor whiteColor];
	modePicker.highlightedTextColor = [UIColor yellowColor];
	
	self.view.layer.shadowOpacity = 0.75f;
	self.view.layer.shadowRadius = 10.0f;
	self.view.layer.shadowColor = [UIColor blackColor].CGColor;
	
	if (![self.slidingViewController.underRightViewController isKindOfClass:[ExperienceListViewController class]])
	{
		self.slidingViewController.underRightViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ExperienceList"];
		[self experiencesChanged];
	}
	
	[self.view addGestureRecognizer:self.slidingViewController.panGesture];
	[self.slidingViewController setAnchorLeftRevealAmount:240.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"Received memory warning");
    [camera stop];
}

#pragma mark - Protocol CvVideoCameraDelegate

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
	NSLog(@"Mode = %@", [self.experienceManager.selected.modes objectAtIndex:item]);
	camera.mode = [self.experienceManager.selected.modes objectAtIndex:item];
}

-(UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)revealExperiences:(id)sender
{
	[self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)markersFound:(NSDictionary*)markers
{
	if([markers count] != 0 || [markerSelection hasStarted])
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
			MarkerAction* markerAction = [self.experienceManager.selected getMarker:marker.codeKey];
			NSLog(@"Marker found: %@", marker.codeKey);
			if (markerAction)
			{
				NSLog(@"Action found: %@", markerAction.code);
				[camera stop];
				[markerSelection reset];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressView setHidden:true];
                });
				if ([markerAction showDetail])
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.progressView setHidden:true];
						[self.slidingViewController performSegueWithIdentifier:@"MarkerActionSegue" sender:markerAction];
						//[self.navigationController performSegueWithIdentifier:@"MarkerActionSegue" sender:markerAction];
						//[self performSegueWithIdentifier:@"MarkerActionSegue" sender:markerAction];
					});
				}
				else
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[markerAction action]]];
				}
			}
		}
	}
}
@end