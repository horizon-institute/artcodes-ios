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

@interface CameraViewController : UIViewController <MarkerFoundDelegate>
{
    MarkerCamera* camera;
}

@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (nonatomic, weak) IBOutlet UIProgressView* progressView;
@property (nonatomic, weak) IBOutlet UICollectionView* modeSelection;

@property (weak, nonatomic) IBOutlet UIView *viewFrameTop;
@property (weak, nonatomic) IBOutlet UIView *viewFrameBottom;


@end
