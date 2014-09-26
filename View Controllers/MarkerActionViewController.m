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
		image = action.image;
	}
	else
	{
		image = @"aestheticodes.png";
	}
	
	NSError* error = nil;
	NSString *path = [[NSBundle mainBundle] pathForResource: @"marker" ofType: @"html"];
	NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];

	NSString* html = [NSString stringWithFormat: res, image, title, actionURL, description];
	
	NSLog(@"%@", html);
	
	[webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
	
	[super viewDidLoad];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	if ( inType == UIWebViewNavigationTypeLinkClicked ) {
		[[UIApplication sharedApplication] openURL:[inRequest URL]];
		return NO;
	}
	
	return YES;
}

@end
