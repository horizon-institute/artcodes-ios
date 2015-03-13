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
#import "Marker.h"
#import "Experience.h"
#import "ExperienceManager.h"
#import "ExperienceViewController.h"
#import "ExperienceEditController.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@interface ExperienceViewController ()

@end

@implementation ExperienceViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.experienceTitle.text = self.experience.name;
	self.experienceDescription.text = self.experience.description;
	
	self.experienceIcon.layer.minificationFilter = kCAFilterTrilinear;
	self.experienceImage.layer.minificationFilter = kCAFilterTrilinear;	
	if(self.experience.icon)
	{
		[self.experienceIcon sd_setImageWithURL:[NSURL URLWithString:self.experience.icon]];
	}

	if(self.experience.image)
	{
		[self.experienceImage sd_setImageWithURL:[NSURL URLWithString:self.experience.image]
								placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL* url){
									self.imageAspect.constant = (image.size.height * self.experienceImage.frame.size.width) / image.size.width;
								}];
	}
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSLog(@"Segue %@", segue.identifier);
	if([segue.identifier isEqual:@"ExperienceEditSegue"])
	{
		// Get reference to the destination view controller
		ExperienceEditController *vc = [segue destinationViewController];
		vc.experienceManager = self.experienceManager;
		vc.experience = self.experience;
	}
}

- (IBAction)share:(id)sender
{
	UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"http://aestheticodes.appspot.com/experience/info/%@", self.experience.id]] applicationActivities:nil];
	[self presentViewController:activityController animated:YES completion:nil];
}
@end

