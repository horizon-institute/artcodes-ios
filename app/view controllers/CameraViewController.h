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
#import "ExperienceManager.h"
#import "ScanViewController.h"

@interface CameraViewController : ScanViewController <ExperienceDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar* toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleItem;
@property (weak, nonatomic) IBOutlet UIView *markerButton;
@property (weak, nonatomic) IBOutlet UIButton* switchAutoOpenButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markerButtonOffset;
@property (weak, nonatomic) IBOutlet UILabel *markerButtonLabel;

@property ExperienceManager* experienceManager;

- (IBAction)showExperiences:(id)sender;
- (IBAction)switchAutoOpen:(id)sender;
- (IBAction)revealExperiences:(id)sender;
- (IBAction)openMarkerAction:(id)sender;

@end
