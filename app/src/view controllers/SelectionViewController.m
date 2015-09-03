/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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

#import "SelectionViewController.h"
#import "CameraViewController.h"
#import "MarkerViewController.h"

@implementation SelectionViewController

- (IBAction)muralButtonPressed:(id)sender
{
	NSString * experienceId = nil;
	if (sender==self.muralButton1)
	{
		experienceId = @"55a4bbf4-0327-426b-b554-8fb064663b8a";
	}
	else if (sender==self.muralButton2)
	{
		experienceId = @"a564fe42-da31-4544-b317-143637bc9c85";
	}
	else if (sender==self.muralButton3)
	{
		experienceId = @"053197ac-eedc-4a3f-a248-4ae21b8fb77a";
	}
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:experienceId forKey:@"experience"];
	[userDefaults synchronize];
	
	
	Experience * experience = [self.experienceManager getExperience:experienceId];
	if (experience != nil && experience.startUpURL != nil)
	{
		[self performSegueWithIdentifier:@"startupSegue" sender:experience];
	}
	else
	{
		[self performSegueWithIdentifier:@"cameraSegue" sender:sender];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[[self.muralButton1 imageView] setContentMode: UIViewContentModeScaleAspectFill];
	[[self.muralButton2 imageView] setContentMode: UIViewContentModeScaleAspectFill];
	[[self.muralButton3 imageView] setContentMode: UIViewContentModeScaleAspectFill];
	
	if (self.experienceManager==nil)
	{
		self.experienceManager = [[ExperienceManager alloc] init];
	}
	self.experienceManager.delegate = nil;
	[self.experienceManager load];
	[self.experienceManager update];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	NSLog(@"Segue %@", segue.identifier);
	
	if ([[segue identifier] isEqualToString:@"cameraSegue"])
	{
		// Get reference to the destination view controller
		CameraViewController *vc = [segue destinationViewController];
		vc.experienceManager = self.experienceManager;
	}
	else if ([[segue identifier] isEqualToString:@"startupSegue"])
	{
		// Get reference to the destination view controller
		MarkerViewController *vc = [segue destinationViewController];
		vc.experience = sender;
		vc.startup = true;
		vc.experienceManager = self.experienceManager;
	}
}

@end
