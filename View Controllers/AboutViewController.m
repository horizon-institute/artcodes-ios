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

@end