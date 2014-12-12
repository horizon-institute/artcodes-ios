//
//  ACFirstViewController.m
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "CameraViewController.h"
#import "MarkerSelection.h"
#import "MarkerCode.h"
#import "Experience.h"
#import "Marker.h"
#import "SlidingViewController.h"
#import "MarkerViewController.h"
#import "ExperienceListViewController.h"
#import "ExperienceSelectionViewController.h"

@interface CameraViewController ()
@property MarkerSelection* markerSelection;
@end

@implementation CameraViewController

-(void)viewDidLoad
{
    [super viewDidLoad];

	self.camera = [[MarkerCamera alloc] init];
	
	self.experienceManager = [[ExperienceManager alloc] init];
	self.experienceManager.delegate = self;
	self.experienceManager.mode = @"detect";
	[self experienceChanged:nil];
	[self.experienceManager silentLogin];
	
	self.camera.experienceManager = self.experienceManager;
	self.markerSelection = [[MarkerSelection  alloc] init];
}

-(void)modeChanged:(NSString *)mode
{
	[self.modeSelection setText:NSLocalizedString([mode stringByAppendingString:@"_selected"], nil)];
}

-(void)experienceChanged:(Experience *)experience
{
	if(experience != nil)
	{
		[self.titleItem setTitle:experience.name];
	}
	else
	{
		[self.titleItem setTitle:@"Aestheticodes"];
	}
	
	[self experiencesChanged];
}

-(void)experiencesChanged
{
	if([self.slidingViewController.underLeftViewController isKindOfClass:[ExperienceSelectionViewController class]])
	{
		ExperienceSelectionViewController* controller = (ExperienceSelectionViewController*)self.slidingViewController.underLeftViewController;
		controller.experienceManager = self.experienceManager;
		[controller.tableView reloadData];
	}
}

-(void)viewDidAppear:(BOOL)animated
{
 	[super viewDidAppear:animated];
	[self.camera start:self.imageView];
    
    // adjust the size of the viewfinder depending on how much of the camera feed we are using:
    CGSize size = [[UIScreen mainScreen] bounds].size;
    float topAndBottomBarSize = 0, leftAndRightBarSize = 0;
    
    if (self.camera.fullSizeViewFinder)
    {
        topAndBottomBarSize = (size.height - size.width)/2.0;
    }
    else
    {
        topAndBottomBarSize = (size.height - size.width/1.4)/2.0;
        leftAndRightBarSize = (size.width - (size.width / 1.4))/2.0;
    }
    self.viewfinderLeftWidth.constant = self.viewfinderRightWidth.constant = leftAndRightBarSize;
    self.viewfinderLeft.hidden = self.viewfinderRight.hidden = self.camera.fullSizeViewFinder;
    
    // minimum sizes insure there is room for the toolbar and mode picker/text
    self.viewfinderTopHeight.constant = topAndBottomBarSize < 60 ? 60 : topAndBottomBarSize;
    self.viewfinderBottomHeight.constant = topAndBottomBarSize < 124 ? 124 : topAndBottomBarSize;
    
	// If the device doesn't have a front camera disable the camera switch button
	//self.flipButton.enabled = [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront];
		
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
    [self.camera start:self.imageView];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBarHidden = false;
	
	[self.camera stop];
}

- (IBAction)flipCamera:(UIBarButtonItem *)sender
{
	[self.camera flip:self.imageView];
}

-(IBAction)showExperiences:(id)sender
{
	[self.slidingViewController performSegueWithIdentifier:@"ExperienceListSegue" sender:sender];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.experienceManager.delegate = self;
	[self experiencesChanged];
	
	self.navigationController.navigationBarHidden = true;
	
	self.view.layer.shadowOpacity = 0.75f;
	self.view.layer.shadowRadius = 10.0f;
	self.view.layer.shadowColor = [UIColor blackColor].CGColor;
	
	if (![self.slidingViewController.underLeftViewController isKindOfClass:[ExperienceSelectionViewController class]])
	{
		self.slidingViewController.underLeftViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ExperienceSelection"];
		[self experiencesChanged];
	}
	
	[self.view addGestureRecognizer:self.slidingViewController.panGesture];
	[self.slidingViewController setAnchorRightRevealAmount:240.0f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
	NSLog(@"Received memory warning");
    [self.camera stop];
}

-(UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)revealExperiences:(id)sender
{
	[self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)markersFound:(NSDictionary*)markers
{
	if([markers count] != 0 || [self.markerSelection hasStarted])
	{
		[self.markerSelection addMarkers:markers];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeSelection setTextColor: [UIColor yellowColor]];
		});
		
		if([self.markerSelection hasTimedOut])
		{
			[self.markerSelection reset];
		}
		else if([self.markerSelection hasFinished])
		{
			MarkerCode* marker = [self.markerSelection getSelected];
			Marker* markerAction = [self.experienceManager.selected getMarker:marker.codeKey];
			NSLog(@"Marker found: %@", marker.codeKey);
			if (markerAction)
			{
				NSLog(@"Action found: %@", markerAction.code);
				[self.camera stop];
				[self.markerSelection reset];
				if ([markerAction showDetail])
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.slidingViewController performSegueWithIdentifier:@"MarkerActionSegue" sender:markerAction];
					});
				}
				else
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[markerAction action]]];
				}
			}
		}
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.modeSelection setTextColor: [UIColor whiteColor]];
		});
	}
}
@end