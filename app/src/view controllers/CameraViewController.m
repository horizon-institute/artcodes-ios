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
		[self.camera stop];
		if ([marker showDetail])
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.slidingViewController performSegueWithIdentifier:@"MarkerActionSegue" sender:marker];
			});
		}
		else
		{
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
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	
	if ([[segue identifier] isEqualToString:@"ExperienceListSegue"])
	{
		// Get reference to the destination view controller
		ExperienceListViewController *vc = [segue destinationViewController];
		vc.experienceManager = self.experienceManager;
	}
}
@end
