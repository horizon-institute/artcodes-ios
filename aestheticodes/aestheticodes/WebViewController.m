//
//  WebViewController.m
//  aestheticodes
//
//  Created by horizon on 19/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSURL* url = [[NSURL alloc] initWithString:@"http://aestheticodes.blogs.wp.horizon.ac.uk/"];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)closeButtonClicked:(id)sender{
    if (self.webView.loading){
        [self.webView stopLoading];
        self.webView.delegate = nil;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
