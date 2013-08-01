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
-(Mat)applythresholdOnImage:(Mat)image;
-(void)displayValidMarkersForImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours hierarchy:(vector<Vec4i>)hierarchy;
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
    //Remove alpha channel as draw functions dont use alpha channel if the image has 4 channels.
    cvtColor(image, image, CV_RGBA2BGR);
    
    //display scan area.
    Scalar scanAreaColor = Scalar(0, 255, 0);
    [self displayRectOnImage:image withColor:scanAreaColor];

    //select image segement to be processed for marker detection.
    cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
    Mat imageSubmat(image,markerRect);
    
    //apply threshold
    Mat thresholdedImage = [self applythresholdOnImage:imageSubmat];
    
    //find contours
    Mat contouredImage = thresholdedImage.clone();
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(contouredImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

    //copy thresholded image to main image for drawing mode.
    if (cameraMode == DRAWING_MODE){
        Mat colorMarkerImage;
        cvtColor(thresholdedImage, colorMarkerImage, CV_GRAY2BGR);
        colorMarkerImage.copyTo(imageSubmat);
        colorMarkerImage.release();

    }
    thresholdedImage.release();
    contouredImage.release();
    
    //display valid markers
    [self displayValidMarkersForImage:imageSubmat withContours:contours hierarchy:hierarchy];
    imageSubmat.release();
    
}


-(Mat)applythresholdOnImage:(Mat)image{
    Mat thresholdedImage;
    //convert image to gray before applying the threshold.
    cvtColor(image, thresholdedImage, CV_BGR2GRAY);
    //apply threshold.
    adaptiveThreshold(thresholdedImage, thresholdedImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 91, 2);
    //threshold(thresholdedImage, thresholdedImage, 0, 255, CV_THRESH_OTSU);
    return thresholdedImage;
}

-(void)displayValidMarkersForImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours hierarchy:(vector<Vec4i>)hierarchy{
    NSMutableDictionary *dtouchCodes = [[NSMutableDictionary alloc] init];
    MarkerConstraint *markerConstraint = [[MarkerConstraint alloc] init];
    
    //color to draw contours
    Scalar markerColor = Scalar(0, 0, 255);
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
            drawContours(image, contours, i, markerColor, 2, 8, hierarchy, 0 );
        }
    }
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
