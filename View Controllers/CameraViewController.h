/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
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
