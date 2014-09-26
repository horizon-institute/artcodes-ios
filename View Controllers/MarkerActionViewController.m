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

@synthesize webView;
@synthesize action;


-(UIStatusBarStyle) preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear: (BOOL)animated
{
    [super viewWillAppear: animated];
	
	NSString* title;
	if(action.title)
	{
		title = [NSString stringWithFormat:action.title, action.code];
	}
	else
	{
		title = [NSString stringWithFormat:@"Marker %@", action.code];
	}
	
	NSString* description;
	if(action.description)
	{
		description = action.description;
	}
	else if (action.action)
	{
		description = action.action;
	}
	
	NSString* actionURL = action.action;
	
	NSString* image;
	if (action.image)
	{
		if([action.image hasPrefix:@"http"])
		{
			image = action.image;
		}
		else
		{
			//NSURL *url = [[NSBundle mainBundle] URLForResource:@"about" withExtension:@"html"];
			//image = [url absoluteString];
		}
	}
	else
	{
		NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"aestheticodes" withExtension:@"png"];
		image = [imageURL absoluteString];
	}
	
	NSError* error = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource: @"marker" ofType: @"html"];
	NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];

	NSString* html = [NSString stringWithFormat: res, image, title, actionURL, description];
	
	NSLog(@"%@", html);
	
	[webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.wornchaos.org"]];
	
	[super viewDidLoad];
}

- (IBAction)open:(id)sender {
	[[UIApplication sharedApplication] openURL:[[NSURL alloc] initWithString:action.action]];
}


@end
