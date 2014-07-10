//
//  MarkerActionViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "MarkerAction.h"
#import "MarkerActionViewController.h"

@interface MarkerActionViewController ()
@end

@implementation MarkerActionViewController

@synthesize action;

- (void)viewWillAppear: (BOOL)animated
{
    [super viewWillAppear: animated];
	
	if(action.title)
	{
		titleLabel.text = [NSString stringWithFormat:action.title, action.code];
	}
	else
	{
		titleLabel.text = [NSString stringWithFormat:@"Marker %@", action.code];
	}
	
	if(action.description)
	{
		descriptionLabel.text = action.description;
	}
	else if (action.action)
	{
		descriptionLabel.text = action.action;
	}
	
	if (action.image)
	{
		if([action.image hasPrefix:@"http"])
		{
			NSURL *URL = [NSURL URLWithString:action.image];
			NSURLRequest *request = [NSURLRequest requestWithURL:URL];
			[NSURLConnection sendAsynchronousRequest:request
											   queue:[NSOperationQueue mainQueue]
								   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
				if (!error)
				{
					self->imageView.image = [UIImage imageWithData:data];
				}
				else
				{
					NSLog(@"Error loading image");
				}
			}];
			

		}
		else
		{
			self->imageView.image = [UIImage imageNamed:action.image];
		}
	}
	else
	{
		//imageView.image = markerImage
	}
	
	[buttonCell setHidden:!action.action];
}

- (IBAction)open:(id *)sender
{
	[[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:action.action]];
}

@end
