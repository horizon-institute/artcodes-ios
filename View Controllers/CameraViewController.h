//
//  ACFirstViewController.h
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "ECSlidingViewController.h"
#import "MarkerCamera.h"
#import "ExperienceDelegate.h"

@interface CameraViewController : UIViewController <ExperienceDelegate>

@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel *modeSelection;

@property (weak, nonatomic) IBOutlet UIToolbar* toolbar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleItem;

- (IBAction)flipCamera:(UIBarButtonItem *)sender;
- (IBAction)revealExperiences:(id)sender;


// Called when the system tells us the app is in the forground
- (void)applicationEnteredForeground:(NSNotification *)notification;

@property (weak, nonatomic) IBOutlet UIView *viewfinderLeft;
@property (weak, nonatomic) IBOutlet UIView *viewfinderRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewfinderTopHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewfinderBottomHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewfinderRightWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewfinderLeftWidth;

@property MarkerCamera* camera;
@property ExperienceManager* experienceManager;

@end
