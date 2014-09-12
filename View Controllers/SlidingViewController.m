//
//  SlidingViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerAction.h"
#import "SlidingViewController.h"
#import "ExperienceViewController.h"
#import "CameraViewController.h"
#import "MarkerActionViewController.h"

@implementation SlidingViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
	{
		self.shouldAdjustChildViewHeightForStatusBar = YES;
		self.statusBarBackgroundView.backgroundColor = [UIColor blackColor];
	}
	
	UIStoryboard *storyboard;
	
	storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
	
	self.topViewController = [storyboard instantiateViewControllerWithIdentifier:@"Camera"];
	self.shouldAddPanGestureRecognizerToTopViewSnapshot = YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	// Remove the forground notification if we segue away.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	
	// Make sure your segue name in storyboard is the same as this line
	if ([[segue identifier] isEqualToString:@"MarkerActionSegue"])
	{
		// Get reference to the destination view controller
		MarkerActionViewController *vc = [segue destinationViewController];
		vc.action = sender;
	}
	else if ([[segue identifier] isEqualToString:@"ExperienceSegue"])
	{
		// Get reference to the destination view controller
		ExperienceViewController *vc = [segue destinationViewController];
		CameraViewController* topView = (CameraViewController*)self.topViewController;
		vc.experience = topView.experienceManager.selected;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
