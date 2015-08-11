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
#import "AppDelegate.h"
#import "CameraViewController.h"
#import "MarkerSelection.h"
#import "MarkerCode.h"
#import "Experience.h"
#import "Marker.h"
#import "UIViewController+ECSlidingViewController.h"
#import "ECSlidingViewController.h"
#import "MarkerViewController.h"
#import "ExperienceListViewController.h"
#import "ExperienceSelectionViewController.h"
#import "OpenInChromeController.h"

#define USE_DEFAULT_COLOUR_EXPERIENCES true
#define USE_DEFAULT_EXTENSION_EXPERIENCES true
#define USE_DEFAULT_COMBINED_EXPERIENCES true

@interface CameraViewController ()

@property bool autoOpen;
@property Marker* marker;

@end

@implementation CameraViewController

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.view addGestureRecognizer:self.slidingViewController.panGesture];
	[self.slidingViewController setAnchorRightRevealAmount:240.0f];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	self.autoOpen = false;
	self.camera = [[MarkerCamera alloc] init];
	
	self.experienceManager = [[ExperienceManager alloc] init];
	self.experienceManager.delegate = self;
	
	AppDelegate *delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
	delegate.manager = self.experienceManager;
	
	[self experienceChanged:nil];
	[self experiencesChanged];
	[self.experienceManager silentLogin];
	
	[CameraViewController addDefaultExperiencesTo:self.experienceManager];
}

+(void)addDefaultExperiencesTo:(ExperienceManager*)experienceManager
{
	
	NSMutableArray* defaultExperiences = [[NSMutableArray alloc] init];
	if (USE_DEFAULT_COLOUR_EXPERIENCES)
	{
		[defaultExperiences addObjectsFromArray:@[
			@{@"name":@"2.1 Red", @"UUID":@"5a5d7329-a73a-45ac-9066-bdc922c93a66", @"colourPreset":@[@"RGB",@(1),@(0),@(0)], @"minRegions":@(5), @"maxRegions":@(6), @"checksum":@(3), @"icon":@"http://www.nottingham.ac.uk/~pszwp/red.gif"},
			@{@"name":@"2.2 Green", @"UUID":@"f988f134-780e-4760-8b65-516663c5fab8", @"colourPreset":@[@"RGB",@(0),@(1),@(0)], @"minRegions":@(5), @"maxRegions":@(6), @"checksum":@(3), @"icon":@"http://www.nottingham.ac.uk/~pszwp/green.gif"},
			@{@"name":@"2.3 Blue", @"UUID":@"3c9833bb-46df-406d-bae6-8d4c0410d02a", @"colourPreset":@[@"RGB",@(0),@(0),@(1)], @"minRegions":@(5), @"maxRegions":@(6), @"checksum":@(3), @"icon":@"http://www.nottingham.ac.uk/~pszwp/blue.gif"}
		]];
	}
	if (USE_DEFAULT_EXTENSION_EXPERIENCES)
	{
		[defaultExperiences addObjectsFromArray:@[
			@{@"name":@"1.1 Area Order", @"UUID":@"6dd56665-8523-43e8-925d-71d6d94be4be", @"minRegions":@(5), @"maxRegions":@(5), @"checksum":@(3), @"description":@"This experience orders the regions of an Artcode by their size. (AREA4321)", @"icon":@"http://www.nottingham.ac.uk/~pszwp/extension.gif", @"version":@(2)},
			@{@"name":@"1.2 Area Label/Orientation Order", @"UUID":@"ce4b84b6-6cfc-4969-a4e4-072334c337b8", @"minRegions":@(5), @"maxRegions":@(5), @"checksum":@(3), @"embeddedChecksum":@(true), @"description":@"This experience labels the regions of an Artcode by their size and then orders them by their orientation. (AO4321)", @"icon":@"http://www.nottingham.ac.uk/~pszwp/extension.gif", @"version":@(2)},
			@{@"name":@"1.3 Orientation Label/Area Order", @"UUID":@"1d4bac87-e9e3-4e12-8208-34c168922e34", @"minRegions":@(5), @"maxRegions":@(5), @"checksum":@(3), @"embeddedChecksum":@(true), @"description":@"This experience labels the regions of an Artcode by their orientation and then orders them by their size. (OA4321)", @"icon":@"http://www.nottingham.ac.uk/~pszwp/extension.gif", @"version":@(2)},
			@{@"name":@"1.4 Touching", @"UUID":@"069674f8-3a8b-49bd-aef6-5b0bc6196c67", @"minRegions":@(5), @"maxRegions":@(5), @"checksum":@(3), @"embeddedChecksum":@(true), @"description":@"This experience counts the number of other regions a region touches. This produces codes like 1-1:1-2:1-2:1-2:2-2 where 1-2 means a region with a value of 1 that is touching 2 other regions. The total of these touching numbers must be disiable by 3. (TOUCH4321)", @"icon":@"http://www.nottingham.ac.uk/~pszwp/extension.gif", @"version":@(2)}
		]];
	}
	if (USE_DEFAULT_COMBINED_EXPERIENCES)
	{
		[defaultExperiences addObjectsFromArray:@[
			@{@"name":@"3.1 Numbers",@"version":@(20),@"UUID":@"133759a3-ff7e-4f35-b545-ed641c109e0b",@"minRegions":@(5),@"maxRegions":@(5),@"checksum":@(3),@"embeddedChecksum":@(true),@"icon":@"http://www.nottingham.ac.uk/~pszwp/combined.gif",@"codes":@[@{@"code":@"1:1:1:1:2",@"title":@"Hi",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5",@"title":@"1",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:2:4",@"title":@"2",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:3:3",@"title":@"3",@"action":@"http://www.google.com"},@{@"code":@"1:1:2:3:5",@"title":@"4",@"action":@"http://www.google.com"},@{@"code":@"1:1:2:4:4",@"title":@"5",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5+1:1:1:2:4",@"title":@"1+2",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5+1:1:1:3:3",@"title":@"1+3",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5+1:1:2:3:5",@"title":@"1+4",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5+1:1:2:4:4",@"title":@"1+5",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:2:4+1:1:1:3:3",@"title":@"2+3",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:2:4+1:1:2:3:5",@"title":@"2+4",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:2:4+1:1:2:4:4",@"title":@"2+5",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:3:3+1:1:2:3:5",@"title":@"3+4",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:3:3+1:1:2:4:4",@"title":@"3+5",@"action":@"http://www.google.com"},@{@"code":@"1:1:2:3:5+1:1:2:4:4",@"title":@"4+5",@"action":@"http://www.google.com"},@{@"code":@"1:1:1:1:5>1:1:1:2:4>1:1:1:3:3>1:1:2:3:5>1:1:2:4:4",@"title":@"1, 2, 3, 4 and 5",@"action":@"http://www.google.com"},@{@"code":@"1:1:2:4:4>1:1:2:3:5>1:1:1:3:3>1:1:1:2:4>1:1:1:1:5",@"title":@"5, 4, 3, 3 and 1",@"action":@"http://www.google.com"}]}
		]];
	}
	
	for (NSDictionary* experienceDict in defaultExperiences)
	{
		Experience* experience = [[Experience alloc] init];
		experience.id = experienceDict[@"UUID"];
		experience.op = @"do-not-touch";
		experience.name = experienceDict[@"name"];
		if (experienceDict[@"icon"] != nil)
			experience.icon = experienceDict[@"icon"];
		if (experienceDict[@"description"] != nil)
			experience.description = experienceDict[@"description"];
		if (experienceDict[@"version"] != nil)
			experience.version = [experienceDict[@"version"] intValue];
		
		if (experienceDict[@"minRegions"] != nil)
			experience.minRegions = [experienceDict[@"minRegions"] intValue];
		if (experienceDict[@"maxRegions"] != nil)
			experience.maxRegions = [experienceDict[@"maxRegions"] intValue];
		if (experienceDict[@"checksum"] != nil)
			experience.checksumModulo = [experienceDict[@"checksum"] intValue];
		if (experienceDict[@"embeddedChecksum"] != nil)
			experience.embeddedChecksum = [experienceDict[@"embeddedChecksum"] boolValue];
		
		if (experienceDict[@"colourPreset"] != nil)
			experience.greyscaleOptions = experienceDict[@"colourPreset"];
		if (experienceDict[@"invertGreyscale"] != nil)
			experience.invertGreyscale = [experienceDict[@"invertGreyscale"] boolValue];
		if (experienceDict[@"hueShift"] != nil)
			experience.hueShift = [experienceDict[@"hueShift"] doubleValue];
		
		if (experienceDict[@"codes"] != nil)
		{
			NSArray* markerDists = experienceDict[@"codes"];
			for (NSDictionary* markerDict in markerDists)
			{
				Marker* marker = [[Marker alloc] init];
				marker.code = markerDict[@"code"];
				if (markerDict[@"title"] != nil)
					marker.title = markerDict[@"title"];
				if (markerDict[@"action"] != nil)
					marker.action = markerDict[@"action"];
				marker.showDetail = true;
				[experience.markers addObject:marker];
			}
		}
		
		Experience* existingExperience = [experienceManager getExperience:experience.id];
		if (existingExperience == nil || existingExperience.version < experience.version)
			[experienceManager add:experience];
	}
	
	[experienceManager save];
}

-(void)experienceChanged:(Experience *)experience
{
	[super experienceChanged:experience];
	
	NSLog(@"Experience changed to %@", experience.name);
	if(experience != nil)
	{
		[self.titleItem setTitle:experience.name forState:UIControlStateNormal];
	}
	else
	{
		[self.titleItem setTitle:@"Artcodes" forState:UIControlStateNormal];
	}
	
	if([self.slidingViewController.underLeftViewController isKindOfClass:[ExperienceSelectionViewController class]])
	{
		ExperienceSelectionViewController* controller = (ExperienceSelectionViewController*)self.slidingViewController.underLeftViewController;
		controller.experienceManager = self.experienceManager;
		controller.experience = self.experience;
		[controller.tableView reloadData];
	}
}

-(void)updateMenu
{
	[super updateMenu];
	if(self.autoOpen)
	{
		[self.switchAutoOpenButton setTitle:@"Open" forState:UIControlStateNormal];
		[self.switchAutoOpenButton setImage:[UIImage imageNamed: @"ic_open_in_new"] forState:UIControlStateNormal];
	}
	else
	{
		[self.switchAutoOpenButton setTitle:@"Popup" forState:UIControlStateNormal];
		[self.switchAutoOpenButton setImage:[UIImage imageNamed: @"ic_popup"] forState:UIControlStateNormal];
	}
}

-(IBAction)openMarkerAction:(id)sender
{
	[self openMarker:self.marker];
}

-(void)openMarker:(Marker*)marker
{
	if (marker)
	{
		NSLog(@"Action found: %@", marker.code);
		[self.markerSelection resetAndResetHistory:marker.resetHistoryOnOpen];
		if ([marker showDetail])
		{
			[self.camera stop];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.slidingViewController performSegueWithIdentifier:@"MarkerActionSegue" sender:marker];
			});
		}
		else if (marker.action!=nil && [marker.action rangeOfString:@"://"].location!=NSNotFound)
		{
			[self.camera stop];
			OpenInChromeController* chromeController = [OpenInChromeController sharedInstance];
			if ([chromeController isChromeInstalled])
			{
				[chromeController openInChrome:[NSURL URLWithString:marker.action]
							   withCallbackURL:[NSURL URLWithString:@"uk.ac.horizon.aestheticodes://"]
								  createNewTab:true];
			}
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.slidingViewController performSegueWithIdentifier:@"MarkerActionSegue" sender:marker];
				});
			}
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No action"
															message:@"No valid action was found for this marker."
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
			[alert show];
		}
	}
}

-(IBAction)switchAutoOpen:(id)sender
{
	self.autoOpen = !self.autoOpen;
	if(self.autoOpen)
	{
		[self hideMarkerButton];
	}
	else
	{
		[self experienceChanged:self.experience.item];
	}
	[self updateMenu];
}

-(void)experiencesChanged
{
	NSString* experienceID = [[NSUserDefaults standardUserDefaults] objectForKey:@"experience"];
	if(experienceID != nil)
	{
		Experience* experience = [self.experienceManager getExperience:experienceID];
		if(experience != nil && experience != self.experience.item)
		{
			self.experience.item = experience;
		}
	}
	
	if(self.experience.item == nil || self.experience.item.id == nil)
	{
		Experience* experience = [self.experienceManager getExperience:@"4c758e29-0759-4583-a0d4-71ee692b7f86"];
		if(experience != nil)
		{
			self.experience.item = experience;
		}
		else if(self.experienceManager.experienceList.count > 0)
		{
			self.experience.item = [self.experienceManager.experienceList objectAtIndex:0];
		}
	}
	
	if([self.slidingViewController.underLeftViewController isKindOfClass:[ExperienceSelectionViewController class]])
	{
		ExperienceSelectionViewController* controller = (ExperienceSelectionViewController*)self.slidingViewController.underLeftViewController;
		controller.experienceManager = self.experienceManager;
		controller.experience = self.experience;
		[controller.tableView reloadData];
	}
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	self.navigationController.navigationBarHidden = false;
	
	[self.camera stop];
}

-(IBAction)showExperiences:(id)sender
{
//	Experience* experience = [[Experience alloc] init];
//	
//	ArtcodeViewController* viewController = [[ArtcodeViewController alloc] initWithExperience:experience delegate:nil];
//	[self.navigationController pushViewController:viewController animated:true];
	
	[self.slidingViewController performSegueWithIdentifier:@"ExperienceListSegue" sender:sender];
}

-(void)markerChanged:(NSString*)markerCode
{
	NSLog(@"Found marker %@", markerCode);
	if(self.autoOpen)
	{
		if(markerCode)
		{
			Marker* marker = [self.experience.item getMarker:markerCode];
			if(marker)
			{
				[self openMarker:marker];
			}
		}
	}
	else
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if(markerCode)
			{
				Marker* marker = [self.experience.item getMarker:markerCode];
				if(marker)
				{
					self.marker = marker;
					if(marker.title)
					{
						self.markerButtonLabel.text = [NSString stringWithFormat:@"Open %@", marker.title];
					}
					else
					{
						self.markerButtonLabel.text = [NSString stringWithFormat:@"Open Marker %@", marker.code];
					}
					if(self.markerButtonOffset.constant != 0)
					{
						self.markerButton.alpha = 1;
						[self.view layoutIfNeeded];
						
						[UIView setAnimationBeginsFromCurrentState:YES];
						[UIView animateWithDuration:.4 animations:^{
							self.markerButtonOffset.constant = 0.0;
							
							[self.view layoutIfNeeded];
						}];
					}
					[self.view layoutIfNeeded];
				}
				else
				{
					[self hideMarkerButton];
				}
			}
			else
			{
				[self hideMarkerButton];
			}
		});
	}
}

-(void)hideMarkerButton
{
	if(self.markerButtonOffset.constant != -100)
	{
		self.markerButton.hidden = false;
		[self.view layoutIfNeeded];
		
		[UIView animateWithDuration:2 animations:^{
			self.markerButtonOffset.constant = -100.0;
			self.markerButton.alpha = 0;
			
			[self.view layoutIfNeeded];
		}];
	}
}

- (IBAction)revealExperiences:(id)sender
{
	if (self.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered)
	{
		[self.slidingViewController anchorTopViewToRightAnimated:YES];
	}
	else
	{
		[self.slidingViewController resetTopViewAnimated:YES];
	}
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	NSLog(@"Segue %@", segue.identifier);
	
	if ([[segue identifier] isEqualToString:@"ExperienceListSegue"])
	{
		// Get reference to the destination view controller
		ExperienceListViewController *vc = [segue destinationViewController];
		vc.experienceManager = self.experienceManager;
	}
}
@end
