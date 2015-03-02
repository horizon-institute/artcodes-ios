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
	[super viewWillAppear:animated];
	
	self.experienceManager.delegate = self;
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.experienceManager.experienceList.count <= indexPath.row)
	{
		Experience* experience = [[Experience alloc] init];
		experience.id = [[NSUUID UUID] UUIDString];
		experience.op = @"create";
		[self performSegueWithIdentifier:@"ExperienceSegue" sender:experience];
	}
	else
	{
		Experience* experience = [self.experienceManager.experienceList objectAtIndex:indexPath.item];
		[self performSegueWithIdentifier:@"ExperienceSegue" sender:experience];
	}
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.experienceManager.experienceList.count + 1;
	}
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.experienceManager.experienceList.count <= indexPath.row)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"AddExperienceCell" forIndexPath: indexPath];
		return cell;
	}
	else
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
		Experience* experience = [self.experienceManager.experienceList objectAtIndex:indexPath.item];
		
		UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
		[label setText:experience.name];
		
		UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:11];
		[imageView.layer setMinificationFilter:kCAFilterTrilinear];
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