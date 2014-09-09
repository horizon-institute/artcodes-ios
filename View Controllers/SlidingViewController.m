//
//  SlidingViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "SlidingViewController.h"

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

@end
