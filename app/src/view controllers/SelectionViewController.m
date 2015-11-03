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

@implementation ContinueAlertDelegate

-(ContinueAlertDelegate*)initWithController:(SelectionViewController*)controller selectedExperienceId:(NSString*)selectedExperienceId savedExperienceId:(NSString*)savedExperienceId
{
	self = [super init];
	if (self!=nil)
	{
		self.selectionViewController = controller;
		self.selectedExperienceId = selectedExperienceId;
		self.savedExperienceId = savedExperienceId;
	}
	return self;
}

- (void)openAlert
{
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:@"Continue?"
						  message:@"Do you want to continue where you were previously or start again?"
						  delegate:self
						  cancelButtonTitle:@"Continue"
						  otherButtonTitles:@"Start again", nil];
	[alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
		// "cancel" / Continue
		[self.selectionViewController startExperienceWithId:self.savedExperienceId];
	} else {
		// "other" / Start again
		[self.selectionViewController startExperienceWithId:self.selectedExperienceId];
	}
	self.selectionViewController.continueAlertDelegate = nil;
	self.selectionViewController = nil;
}

@end

@implementation SelectionViewController

- (IBAction)muralButtonPressed:(id)sender
{
	NSString * selectedExperienceId = nil;
	if (sender==self.muralButton1)
	{
		selectedExperienceId = @"55a4bbf4-0327-426b-b554-8fb064663b8a";
	}
	else if (sender==self.muralButton2)
	{
		selectedExperienceId = @"a564fe42-da31-4544-b317-143637bc9c85";
	}
	else if (sender==self.muralButton3)
	{
		selectedExperienceId = @"053197ac-eedc-4a3f-a248-4ae21b8fb77a";
	}
	
	Experience * selectedExperience = [self.experienceManager getExperience:selectedExperienceId];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString* savedExperienceId = [userDefaults stringForKey:@"experience"];
	Experience * savedExperience = [self.experienceManager getExperience:savedExperienceId];
	
	if (savedExperienceId==nil || [savedExperienceId isEqualToString:selectedExperienceId] || ![[savedExperience name] isEqualToString:[selectedExperience name]])
	{
		[self startExperienceWithId:selectedExperienceId];
	}
	else
	{
		self.continueAlertDelegate = [[ContinueAlertDelegate alloc] initWithController:self selectedExperienceId:selectedExperienceId savedExperienceId:savedExperienceId];
		[self.continueAlertDelegate openAlert];
	}
}

-(void)startExperienceWithId:(NSString*)experienceId
{
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
		[self performSegueWithIdentifier:@"cameraSegue" sender:self];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	if (self.experienceManager==nil)
	{
		self.experienceManager = [[ExperienceManager alloc] init];
	}
	self.experienceManager.delegate = nil;
	[self.experienceManager load];
	
	[self updateButtons];
	
	dispatch_queue_t lowPriorityQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_async(lowPriorityQueue, ^{
		[self.experienceManager update];
		[self updateButtons];
	});
}

-(void)updateButtons
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray* buttons = @[self.muralButton1,self.muralButton2,self.muralButton3];
		NSArray* experenceIds = @[@"55a4bbf4-0327-426b-b554-8fb064663b8a",@"a564fe42-da31-4544-b317-143637bc9c85",@"053197ac-eedc-4a3f-a248-4ae21b8fb77a"];
		
		for (int i=0; i<[experenceIds count]; ++i)
		{
			if (buttons[i] != nil)
			{
				[[buttons[i] imageView] setContentMode: UIViewContentModeScaleAspectFill];
				NSString* experienceId = experenceIds[i];
				Experience* experence = [self.experienceManager getExperience:experienceId];
				[buttons[i] setEnabled:!(experence==nil || experence.comingSoon)];
			}
		}
	});
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
