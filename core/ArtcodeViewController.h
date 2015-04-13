/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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
#import "MarkerCamera.h"
#import "ExperienceController.h"

@protocol ArtcodeDelegate <NSObject>

-(void)markerFound:(NSString*)markers;

@end

@interface ArtcodeViewController : UIViewController <ExperienceControllerDelegate, ScanDelegate>

@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel* modeLabel;

@property (weak, nonatomic) IBOutlet UIView* menu;
@property (weak, nonatomic) IBOutlet UIButton* menuButton;
@property (weak, nonatomic) IBOutlet UIButton* switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton* switchThresholdDisplayButton;
@property (weak, nonatomic) IBOutlet UIButton* switchMarkerDisplayButton;
@property (weak, nonatomic) IBOutlet UIButton* backButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* viewfinderTopHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* viewfinderBottomHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* viewfinderRightWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint* viewfinderLeftWidth;

@property (weak) id<ArtcodeDelegate> delegate;

@property MarkerCamera* camera;
@property ExperienceController* experience;

-(id)initWithExperience:(Experience*)experience delegate:(id<ArtcodeDelegate>)delegate;

-(IBAction)switchCamera:(id)sender;
-(IBAction)switchThresholdDisplay:(id)sender;
-(IBAction)switchMarkerDisplay:(id)sender;
- (IBAction)back:(id)sender;

-(void)updateMenu;
-(void)markerChanged:(NSString*)markerCode;
-(IBAction)showMenu:(id)sender;
-(IBAction)hideMenu:(id)sender;

// Called when the system tells us the app is in the forground
- (void)applicationEnteredForeground:(NSNotification *)notification;

@end
