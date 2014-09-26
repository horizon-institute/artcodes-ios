//
//  AboutViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Experience.h"

@interface AboutViewController : UIViewController<UIWebViewDelegate>

@property IBOutlet UIWebView *webView;

@property Experience* experience;
@end