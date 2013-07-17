//
//  ACFirstViewController.h
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface ACScanViewController : UIViewController <CvVideoCameraDelegate>{
    IBOutlet UIImageView* imageView;
    CvVideoCamera* videoCamera;
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;

@end
