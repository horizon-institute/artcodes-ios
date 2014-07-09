//
//  ACFirstViewController.h
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "MarkerCamera.h"
#import "MarkerFoundDelegate.h"
#import "AKPickerView.h"

@interface CameraViewController : UIViewController <MarkerFoundDelegate, AKPickerViewDelegate>
{
    MarkerCamera* camera;
}

@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (nonatomic, weak) IBOutlet UIProgressView* progressView;
@property (weak, nonatomic) IBOutlet AKPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *modeSelectionMark;

@property (weak, nonatomic) IBOutlet UIView *viewFrameTop;
@property (weak, nonatomic) IBOutlet UIView *viewFrameBottom;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *flipButton;

- (IBAction)flipCamera:(UIBarButtonItem *)sender;

@end
