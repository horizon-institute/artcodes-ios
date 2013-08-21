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
#import "TemporalMarkers.h"
#import "WebViewController.h"

enum CameraMode{
    DETECTION_MODE,
    DRAWING_MODE
};

@interface ACScanViewController ()
@property int cameraMode;
@property TemporalMarkers *temporalMarkers;

-(Mat)applythresholdOnImage:(Mat)image;
-(NSDictionary*)detectMarkersForImageHierarchy:(vector<Vec4i>)hierarchy andImageContour:(vector<vector<cv::Point>>)contours;
-(void)displayContoursForMarkers:(NSDictionary*)markers forMarkerImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy;
-(void)displayWebViewController;
//-(void)updateProgressView;
-(void)markerDetected;
@end

@implementation ACScanViewController

@synthesize videoCamera;
@synthesize cameraMode;
@synthesize temporalMarkers;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS =  10;
    self.videoCamera.grayscaleMode = NO;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCameraModeViewTap:)];
    [cameraModeView addGestureRecognizer:singleTap];
    self.cameraMode = DETECTION_MODE;
    temporalMarkers = [[TemporalMarkers alloc] init];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.videoCamera start];
}


-(void)viewDidDisappear:(BOOL)animated{
    if ([self.videoCamera running])
        [self.videoCamera stop];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self.videoCamera stop];
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
    Mat markerImage(image,markerRect);
    
    //apply threshold
    Mat thresholdedImage = [self applythresholdOnImage:markerImage];
    
    //find contours
    Mat contouredImage = thresholdedImage.clone();
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(contouredImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

    //copy thresholded image to main image for drawing mode.
    if (cameraMode == DRAWING_MODE){
        Mat colorMarkerImage;
        cvtColor(thresholdedImage, colorMarkerImage, CV_GRAY2BGR);
        colorMarkerImage.copyTo(markerImage);
        colorMarkerImage.release();

    }
    thresholdedImage.release();
    contouredImage.release();
    
    //detect markers
    NSDictionary* markers = [self detectMarkersForImageHierarchy:hierarchy andImageContour:contours];
    
    if (markers.count > 0){
        Scalar scanAreaColor = Scalar(0, 0, 255);
        [self displayRectOnImage:image withColor:scanAreaColor];
        
        if (cameraMode == DETECTION_MODE){
            [self processDetectionModeWithMakrers:markers forMarkerImage:markerImage withFullImage:image withContours:contours andHierarchy:hierarchy];
        }
        else if (cameraMode == DRAWING_MODE){
            [self processDrawingModeWithMarkers:markers forImage:markerImage withContours:contours andHierarchy:hierarchy];
        }
    }
    
    markerImage.release();
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

-(NSDictionary*)detectMarkersForImageHierarchy:(vector<Vec4i>)hierarchy andImageContour:(vector<vector<cv::Point>>)contours{
    MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:hierarchy imageContours:contours];
    return [markerDetector findMarkers];
}


-(void)displayContoursForMarkers:(NSDictionary*)markers forMarkerImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy{
    
    //color to draw contours
    Scalar markerColor = Scalar(0, 0, 255);
    
    for (NSString *markerCode in markers){
        DtouchMarker *marker = [markers objectForKey:markerCode];
        for (NSNumber *nodeIndex in [marker getNodeIndexes])
            drawContours(image, contours, [nodeIndex integerValue], markerColor, 2, 8, hierarchy, 0);
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

-(void)processDrawingModeWithMarkers:(NSDictionary*)markers forImage:(Mat&)markerImage withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy{
    
    if (markers.count > 0 )
    {
        [self displayContoursForMarkers:markers forMarkerImage:markerImage withContours:contours andHierarchy:hierarchy];
    }
}

-(void)processDetectionModeWithMakrers:(NSDictionary*) markers forMarkerImage:(Mat&)markerImage withFullImage:(Mat&)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy
{
    //cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
    if (markers.count > 0 )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //started
            if ([temporalMarkers hasIntegrationStarted])
            {
                [progressView setProgress:0.0];
                progressView.hidden = false;
            }
                
            float percent = [temporalMarkers getIntegrationPercent];
            if (percent == 1.0){
                progressView.hidden = true;
            }
            [progressView setProgress:percent animated:YES];
        });
        
        //add markers into list
        [temporalMarkers integrateMarkers:markers];
        
        if([temporalMarkers isMarkerDetectionTimeUp]){
            //DtouchMarker* marker = [temporalMarkers guessMarker];
            //display valid markers
            /*
            [self displayContoursForMarkers:markers forMarkerImage:markerImage withContours:contours andHierarchy:hierarchy];
            if (marker){
                cv::Point point;
                int fontFace = FONT_HERSHEY_PLAIN;
                double fontScale = 2;
                int thickness = 3;
                int baseline = 0;
                Scalar textColor = Scalar(0,0,255);
                
                const string text = [marker.codeKey UTF8String];
                cv::Size textSize = cv::getTextSize(text, fontFace, fontScale, thickness, &baseline);
                baseline+= thickness;
                
                cv::Point textOrg((markerRect.width - textSize.width) / 2 + markerRect.x, markerRect.y - 10);
                
                cv::putText(image, text, textOrg, FONT_HERSHEY_PLAIN, 1.5, textColor, 2, 8, false);
                
            }
             */
            
            //[self performSelectorOnMainThread:@selector(markerDetected) withObject:nil waitUntilDone:FALSE];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.videoCamera running]){
                    [self.videoCamera stop];
                }
                [temporalMarkers resetTemporalMarker];
                [self displayWebViewController];
            });
        }
    }
}

-(void)markerDetected{
    if ([self.videoCamera running]){
        [self.videoCamera stop];
    }
    [temporalMarkers resetTemporalMarker];
    [self displayWebViewController];
}

/*
-(void)updateProgressView{
    float percent = [temporalMarkers getIntegrationPercent];
    //just started.
    if (percent == 0){
        progressView.hidden = false;
    }
    else if (percent == 1.0){
        progressView.hidden = true;
    }
    [progressView setProgress:percent animated:YES];
}
*/

-(void)displayWebViewController{
    WebViewController *webViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    [self presentViewController:webViewController animated:YES completion:nil];
}

@end
