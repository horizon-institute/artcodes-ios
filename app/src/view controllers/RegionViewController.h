//
//  RegionViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 13/03/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

#import "Experience.h"
#import <UIKit/UIKit.h>

@interface RegionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *minSlider;
@property (weak, nonatomic) IBOutlet UISlider *maxSlider;
@property (weak, nonatomic) IBOutlet UILabel *regionLabel;

@property Experience* experience;

@end
