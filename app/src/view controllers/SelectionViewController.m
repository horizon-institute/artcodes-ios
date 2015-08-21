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

@implementation SelectionViewController

- (IBAction)muralButtonPressed:(id)sender
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (sender==self.muralButton1)
	{
		[userDefaults setObject:@"5a5d7329-a73a-45ac-9066-bdc922c93a66" forKey:@"experience"];
	}
	else if (sender==self.muralButton2)
	{
		[userDefaults setObject:@"f988f134-780e-4760-8b65-516663c5fab8" forKey:@"experience"];
	}
	else if (sender==self.muralButton3)
	{
		[userDefaults setObject:@"3c9833bb-46df-406d-bae6-8d4c0410d02a" forKey:@"experience"];
	}
	[userDefaults synchronize];
	
	[self performSegueWithIdentifier:@"cameraSegue" sender:sender];
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
}

@end
