//
//  AboutViewController.m
//  aestheticodes
//
//  Created by horizon on 09/09/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

@synthesize aboutView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
		NSDictionary *textTitleOptions = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor blueColor], UITextAttributeTextColor, [UIColor whiteColor], UITextAttributeTextShadowColor, nil];
		[[UINavigationBar appearance] setTitleTextAttributes:textTitleOptions];
		
		
		
	}
	return self;
}


- (void)viewDidLoad
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"about" withExtension:@"html"];
	[aboutView loadRequest:[NSURLRequest requestWithURL:url]];
	
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

//Make sure the about information opens in Safari
-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
	if ( inType == UIWebViewNavigationTypeLinkClicked )
	{
		[[UIApplication sharedApplication] openURL:[inRequest URL]];
		return NO;
	}
	
	return YES;
}


@end