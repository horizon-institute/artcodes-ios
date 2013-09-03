//
//  WebViewController.h
//  aestheticodes
//
//  Created by horizon on 19/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DtouchMarker.h"

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property DtouchMarker* marker;
@property IBOutlet UIWebView *webView;

-(IBAction)closeButtonClicked:(id)sender;

@end
