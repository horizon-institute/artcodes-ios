//
//  ExperienceListViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ExperienceListViewController.h"
#import "ExperienceEditController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ExperienceListViewController ()
@end

@implementation ExperienceListViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(void)markersFound:(NSDictionary *)markers
{
	
}

-(void)modeChanged:(NSString *)mode
{
	
}

-(void)experienceChanged:(Experience *)experience
{
	[self.tableView reloadData];
}

-(void)experiencesChanged
{
	[self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
	self.experienceManager.delegate = self;
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.experienceManager.count <= indexPath.row)
	{
		Experience* experience = [[Experience alloc] init];
		experience.id = [[NSUUID UUID] UUIDString];
		experience.op = @"create";
		[self performSegueWithIdentifier:@"ExperienceSegue" sender:experience];
	}
	else
	{
		Experience* experience = [self.experienceManager getExperience:indexPath];
		[self performSegueWithIdentifier:@"ExperienceSegue" sender:experience];
	}
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.experienceManager.count + 1;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.experienceManager.count <= indexPath.row)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddExperienceCell" forIndexPath: indexPath];
		return cell;
	}
	else
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
		Experience* experience = [self.experienceManager getExperience:indexPath];
		
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
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	[super prepareForSegue:segue sender:sender];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
	if ([[segue identifier] isEqualToString:@"ExperienceSegue"])
	{
		// Get reference to the destination view controller
		ExperienceEditController *vc = [segue destinationViewController];
		vc.experienceManager = self.experienceManager;
		vc.experience = sender;
	}
}
@end