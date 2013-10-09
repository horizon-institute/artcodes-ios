//
//  WebViewController.m
//  aestheticodes
//
//  Created by horizon on 19/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "WebViewController.h"
#import "ACMarkerDB.h"

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize webView;
@synthesize marker;

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
}

-(void)viewDidAppear:(BOOL)animated
{
    if (marker != nil){
        NSString* markerUrl = [[ACMarkerDB getSharedInstance] getUrlStringForMarker:marker];
        NSURL* url = [[NSURL alloc] initWithString:markerUrl];
        NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
        [self.webView loadRequest:request];
    }
    
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}


-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Show webpage", nil) message:NSLocalizedString(@"Error in downloading the webpage", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

@end
