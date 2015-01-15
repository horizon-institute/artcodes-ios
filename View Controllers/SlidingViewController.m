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
