//
//  ChecksumViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 16/03/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

#import "Experience.h"
#import <UIKit/UIKit.h>

@interface ChecksumViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *propertyDescription;
@property (weak, nonatomic) IBOutlet UISlider *propertySlider;
@property (weak, nonatomic) IBOutlet UILabel *propertyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *embeddedSwitch;
@property (weak, nonatomic) IBOutlet UILabel *embeddedLabel;

@property Experience* experience;

@end
