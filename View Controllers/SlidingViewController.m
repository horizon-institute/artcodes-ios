//
//  SlidingViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "Marker.h"
#import "SlidingViewController.h"
#import "ExperienceListViewController.h"
#import "CameraViewController.h"
#import "MarkerViewController.h"

@implementation SlidingViewController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	// Remove the forground notification if we segue away.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	
	// Make sure your segue name in storyboard is the same as this line
	if ([[segue identifier] isEqualToString:@"MarkerActionSegue"])
	{
		// Get reference to the destination view controller
		MarkerViewController *vc = [segue destinationViewController];
		vc.action = sender;
	}
	else if ([[segue identifier] isEqualToString:@"ExperienceListSegue"])
	{
		// Get reference to the destination view controller
		ExperienceListViewController *vc = [segue destinationViewController];
		CameraViewController* topView = (CameraViewController*)self.topViewController;
		vc.experienceManager = topView.experienceManager;
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
