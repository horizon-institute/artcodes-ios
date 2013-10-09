//
//  ACDrawingViewController.h
//  aestheticodes
//
//  Created by horizon on 23/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>

using namespace cv;

@interface ACDrawingViewController : UIViewController<CvVideoCameraDelegate>{
    CvVideoCamera* videoCamera;
    
}

@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property IBOutlet UIImageView* imageView;

@end
