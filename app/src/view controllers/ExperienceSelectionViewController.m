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
#import "ExperienceSelectionViewController.h"
#import "ExperienceEditController.h"
#import "ExperienceViewController.h"
#import "CameraViewController.h"
#import "UIViewController+ECSlidingViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GPPSignInButton.h"
#import "GTLPlusPerson.h"

@interface ExperienceSelectionViewController ()
@property int cameras;
@end

@implementation ExperienceSelectionViewController

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	NSArray *devices = [AVCaptureDevice devices];
	self.cameras = 0;
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device hasMediaType:AVMediaTypeVideo])
		{
			self.cameras++;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.edgesForExtendedLayout = UIRectEdgeLeft;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		Experience* experience = [self.experienceManager.experienceList objectAtIndex:indexPath.item];
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:experience.id forKey:@"experience"];
		[userDefaults synchronize];
		NSLog(@"Selected %@", experience.id);
		self.experience.item = experience;
	}
	else
	{
		if([self.experienceManager loggedIn])
		{
			UIAlertView* alert = [[UIAlertView alloc] init];
			alert.title = @"Logout";
			alert.message = @"Would you like to logout?";
			alert.delegate = self;
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Logout"];
			[alert show];
		}
		else
		{
			[self.experienceManager login];
		}
	}
	[self.slidingViewController resetTopViewAnimated:YES];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.experienceManager.experienceList.count;
	}
	return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
	UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
	UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:11];

	if(indexPath.section == 0)
	{
		Experience* experience = [self.experienceManager.experienceList objectAtIndex:indexPath.item];
		if(self.experience != nil && self.experience.item == experience)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		[label setText:experience.name];
		[imageView.layer setMinificationFilter:kCAFilterTrilinear];
		if(experience.icon != nil)
		{
			[imageView sd_setImageWithURL:[NSURL URLWithString:experience.icon]];
		}
		else
		{
			[imageView setImage:nil];
		}
	}
	else
	{
		if([self.experienceManager loggedIn])
		{
			[label setText:@"Logout"];
			GTLPlusPerson* user = [self.experienceManager getUser];
			if(user != nil)
			{
				UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:11];
				imageView.layer.cornerRadius = imageView.frame.size.height /2;
				imageView.layer.masksToBounds = YES;
				imageView.layer.borderWidth = 0;
				if(user.image != nil && user.image.url != nil)
				{
					[imageView sd_setImageWithURL:[NSURL URLWithString:user.image.url]];
				}
				else
				{
					[imageView setImage:nil];
				}
			}
		}
		else
		{
			[label setText:@"Login"];
			[imageView setImage:nil];
		}
	}
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 1:
			[self.experienceManager logout];
			break;
		default:
			NSLog(@"Delete was cancelled by the user");
	}
}

@end
