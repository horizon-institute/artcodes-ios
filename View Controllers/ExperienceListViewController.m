//
//  ExperienceListViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ExperienceListViewController.h"
#import "ExperienceViewController.h"

@interface ExperienceListViewController ()
@property NSMutableDictionary* images;
@property UIImage* loadingImage;
@end

@implementation ExperienceListViewController

@synthesize images;
@synthesize loadingImage;

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	images = [[NSMutableDictionary alloc] init];
	loadingImage = [[UIImage alloc] init];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Experience* experience = [self getExperience:indexPath];
	if(indexPath.section == 0)
	{
		[self.slidingViewController performSegueWithIdentifier:@"ExperienceSegue" sender:self];
		[self.slidingViewController resetTopView];
	}
	else
	{
		self.experienceManager.selected = experience;
		if(self.experienceManager.delegate != nil)
		{
			[self.experienceManager.delegate experienceChanged:experience];
		}
		[self.slidingViewController resetTopView];
	}
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		if(self.experienceManager.selected != nil)
		{
			return 1;
		}
		return 0;
	}

	if(self.experienceManager.selected != nil)
	{
		return [self.experienceManager.experiences count] - 1;
	}

	return [self.experienceManager.experiences count];
}

-(Experience*)getExperience:(NSIndexPath*) indexPath
{
	if(indexPath.section == 0)
	{
		return self.experienceManager.selected;
	}
	else
	{
		if(self.experienceManager.selected != nil)
		{
			NSMutableArray* array = [NSMutableArray arrayWithArray: self.experienceManager.experiences];
			[array removeObject:self.experienceManager.selected];
			return [array objectAtIndex:indexPath.row];
		}
		else
		{
			return [self.experienceManager.experiences objectAtIndex:indexPath.row];
		}
	}
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell;
	Experience* experience = [self getExperience:indexPath];
	if(indexPath.section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"SelectedExperienceCell" forIndexPath: indexPath];
		UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
		[label setText:[NSString stringWithFormat:@"%@ Markers", experience.name]];
	}
	else
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"ExperienceCell" forIndexPath: indexPath];
		UILabel *label = (UILabel *)[cell.contentView viewWithTag:9];
		[label setText:experience.name];
	}
	
	UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:11];
	if(experience.icon != nil)
	{
		UIImage* image = [images objectForKey:experience.id];
		if(image != nil)
		{
			if(image == loadingImage)
			{
				[imageView setImage:nil];
			}
			else
			{
				[imageView setImage:image];
			}
		}
		else
		{
			[imageView setImage:nil];
			[images setValue:loadingImage forKey:experience.id];
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				Experience* experience = [self getExperience:indexPath];
				NSURL *url = [NSURL URLWithString:experience.icon];
				NSURLRequest *request = [NSURLRequest requestWithURL:url];
				
				NSURLResponse* response = nil;
				NSError* error = nil;
				NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
				if(data != nil)
				{
					UIImage *image = [UIImage imageWithData:data];
					if(image != nil)
					{
						dispatch_async(dispatch_get_main_queue(), ^{
							[images setValue:image forKey:experience.id];
							[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
							NSLog(@"Image loaded %@", url);
						});
					}
				}
				else if(error != nil)
				{
					NSLog(@"%@", error);
				}
			});
		}
	}
	else
	{
		[imageView setImage:nil];
	}
	
	return cell;
}

@end