//
//  ACFirstViewController.m
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "ACScanViewController.h"
#import "MarkerDetector.h"
#import "DtouchMarker.h"
#import "MarkerConstraint.h"

enum CameraMode{
    DETECTION_MODE,
    DRAWING_MODE
};

@interface ACScanViewController ()
@property int cameraMode;
@end

@implementation ACScanViewController

@synthesize videoCamera;
@synthesize cameraMode;

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
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCameraModeViewTap:)];
    [cameraModeView addGestureRecognizer:singleTap];
    self.cameraMode = DETECTION_MODE;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.videoCamera start];
}

/*
-(void)viewDidDisappear:(BOOL)animated{
    [self.videoCamera stop];
}
*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Protocol CvVideoCameraDelegate

-(void)processImage:(Mat&)image
{
    
    Mat markerImage;
    NSMutableDictionary *dtouchCodes = [[NSMutableDictionary alloc] init];
    //Remove alpha channel as draw functions dont use alpha channel if the image has 4 channels.
    cvtColor(image, image, CV_RGBA2BGR);
    
    if (self.cameraMode == DRAWING_MODE){
        cvtColor(image, image, CV_BGR2GRAY);
    }
    
    //convert input image into gray as thresholding requires image in gray scale.
    cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
    Mat imageSubmat(image,markerRect);
    
    if (self.cameraMode == DETECTION_MODE)
        cvtColor(imageSubmat, markerImage, CV_BGR2GRAY);
    else
        markerImage = imageSubmat.clone();
    
    //applying thresholding on the image segment.
    //adaptiveThreshold(markerImage, markerImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 91, 2);
    threshold(markerImage, markerImage, 0, 255, CV_THRESH_OTSU);
    
    //find contours
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(markerImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    markerImage.release();
    
    Scalar scanAreaColor = Scalar(0, 255, 0);
    [self displayRectOnImage:image withColor:scanAreaColor];
    
    Scalar markerColor = Scalar(0, 0, 255);
    
    MarkerConstraint *markerConstraint = [[MarkerConstraint alloc] init];
    for (int i = 0; i < contours.size(); i++)
    {
        MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:hierarchy];
        DtouchMarker* newMarker = [markerDetector getDtouchMarkerForNode:i];
        if (newMarker != nil && [markerConstraint isValidDtouchMarker:newMarker]){
            //if code is already detected.
            DtouchMarker *existingMarker = [dtouchCodes valueForKey:newMarker.codeKey];
            if (existingMarker != nil){
                existingMarker.occurence++;
            }else{
                [dtouchCodes setObject:newMarker forKey:newMarker.codeKey];
            }
            drawContours(imageSubmat, contours, i, markerColor, 2, 8, hierarchy, 0 );
        }
    }

    /*
    NSString* key;

    for (key in dtouchCodes){
        DtouchMarker *dtouchMarker = [dtouchCodes objectForKey:key];
        NSLog(@"Node index %d and code %@", dtouchMarker.nodeIndex, dtouchMarker.codeKey);
    }*/
}

//calculate region in the image which is used for marker detection.
-(cv::Rect) calculateMarkerImageSegmentArea:(Mat)image{
    int width = image.cols;
    int height = image.rows;
    
    int imgWidth = width * 0.50;
    int imgHeight = imgWidth;
    
    int x = (width - imgWidth) / 2;
    int y = (height - imgHeight) / 2;
    
    return cv::Rect(x, y, imgWidth, imgHeight);
}

-(void)handleCameraModeViewTap:(UITapGestureRecognizer*)recognizer{
    if (self.cameraMode == DETECTION_MODE)
        self.cameraMode = DRAWING_MODE;
    else
        self.cameraMode = DETECTION_MODE;
}

-(void)displayRectOnImage:(Mat)image withColor:(Scalar)color{
    cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
    rectangle(image, rect, color, 3); 
}

@end
