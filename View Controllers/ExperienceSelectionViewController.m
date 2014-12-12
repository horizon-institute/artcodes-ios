//
//  ExperienceListViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ExperienceSelectionViewController.h"
#import "ExperienceViewController.h"
#import "CameraViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GPPSignInButton.h"
#import "GTLPlusPerson.h"

@interface ExperienceSelectionViewController ()
@property int cameras;
@end

@implementation ExperienceSelectionViewController

-(void)viewDidLoad
{
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
	
	CGRect frame = self.tableView.frame;
	[self.tableView setFrame:CGRectMake(frame.origin.x, frame.origin.y, 240, frame.size.height)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(self.cameras > 1)
	{
		return 4;
	}
	return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		self.experienceManager.selected = [self.experienceManager getExperience:indexPath];
	}
	else if(indexPath.section == 1)
	{
		self.experienceManager.mode = [self.experienceManager.modes objectAtIndex:indexPath.row];
	}
	else if(indexPath.section == 2 && self.cameras > 1)
	{
		UIViewController* topView = [self.slidingViewController topViewController];
		if([topView isKindOfClass:[CameraViewController class]])
		{
			CameraViewController* cameraView = (CameraViewController*)topView;
			[cameraView flipCamera:nil];
		}
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
	[self.slidingViewController resetTopView];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.experienceManager.count;
	}
	else if(section == 1)
	{
		return self.experienceManager.modes.count;
	}
	else if(section == 2)
	{
		return 1;
	}
	else if(section == 3)
	{
		return 1;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		Experience* experience = [self.experienceManager getExperience:indexPath];
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
		if(self.experienceManager.selected == experience)
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
		[label setText:experience.name];
		
		UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:11];
		if(experience.icon != nil)
		{
			[imageView sd_setImageWithURL:[NSURL URLWithString:experience.icon]];
		}
		else
		{
			[imageView setImage:nil];
		}
		
		return cell;
	}
	else if(indexPath.section == 1)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ModeCell" forIndexPath: indexPath];
		NSString* mode = [self.experienceManager.modes objectAtIndex:indexPath.row];
		[cell.textLabel setText:NSLocalizedString(mode, nil)];
		[cell.imageView setImage:nil];
		
		if([mode isEqualToString:self.experienceManager.mode])
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		return cell;
	}
	else if(indexPath.section == 2 && self.cameras > 1)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCameraCell" forIndexPath: indexPath];
		return cell;
	}
	else
	{
		if([self.experienceManager loggedIn])
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
			UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
			GTLPlusPerson* user = [self.experienceManager getUser];
			[label setText:@"Logout"];
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
			
			return cell;
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ModeCell" forIndexPath: indexPath];
			[cell.textLabel setText:@"Login"];
			
			return cell;
		}
	}
	return nil;
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
