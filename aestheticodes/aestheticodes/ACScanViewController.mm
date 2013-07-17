//
//  ACFirstViewController.m
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "ACScanViewController.h"

@interface ACScanViewController ()

@end

@implementation ACScanViewController

@synthesize videoCamera;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS =  30;
    self.videoCamera.grayscaleMode = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.videoCamera start];
}

-(void)viewDidDisappear:(BOOL)animated{
    [self.videoCamera stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Protocol CvVideoCameraDelegate

-(void)processImage:(Mat&)image
{
    Mat markerImage;
    //Mat thresholdedImage;
    //convert input image into gray as thresholding requires image in gray scale.
    cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
    Mat imageSubmat(image,markerRect);
    cvtColor(imageSubmat, markerImage, CV_BGR2GRAY);
    
    //applying thresholding on the image segment.
    adaptiveThreshold(markerImage, markerImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 91, 2);
    //find contours
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(markerImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    markerImage.release();
    
    Scalar color = Scalar(0,255,0);
    
    for (int i = 0; i < contours.size(); i++)
    {
        drawContours(imageSubmat, contours, i, color, 2, 8, hierarchy, 0 );
    }
    
}

//calculate region in the image which is used for marker detection.
-(cv::Rect) calculateMarkerImageSegmentArea:(Mat)image{
    int width = image.cols;
    int height = image.rows;
    
    int imgWidth = width * 0.70;
    int imgHeight = imgWidth;
    
    int x = (width - imgWidth) / 2;
    int y = (height - imgHeight) / 2;
    
    return cv::Rect(x, y, imgWidth, imgHeight);
}


@end
