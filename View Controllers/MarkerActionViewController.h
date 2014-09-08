//
//  MarkerActionViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface MarkerActionViewController : UIViewController {
	IBOutlet UIView* view;
	
	IBOutlet UIImageView* imageView;
	IBOutlet UILabel* titleLabel;
	IBOutlet UILabel* descriptionLabel;

	IBOutlet UIButton* button;
}

@property MarkerAction* action;

@end