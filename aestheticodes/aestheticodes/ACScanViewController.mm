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

@interface ACScanViewController ()
@property TemporalMarkers *temporalMarkers;

-(Mat)applythresholdOnImage:(Mat)image;
-(NSDictionary*)detectMarkersForImageHierarchy:(vector<Vec4i>)hierarchy andImageContour:(vector<vector<cv::Point>>)contours;
-(void)displayContoursForMarkers:(NSDictionary*)markers forMarkerImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy;
-(void)displayWebViewControllerForMarker:(DtouchMarker*)marker;
@end

@implementation ACScanViewController

@synthesize videoCamera;
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
    temporalMarkers = [[TemporalMarkers alloc] init];
    
    
    
    //Set tab images
    UITabBar *tabBar = self.tabBarController.tabBar;
    UITabBarItem *drawing = [tabBar.items objectAtIndex:1];
    UITabBarItem *settings = [tabBar.items objectAtIndex:2];
    
    
    [drawing setFinishedSelectedImage:[UIImage imageNamed:@"drawingDark.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"drawingLight.png"]];
    [settings setFinishedSelectedImage:[UIImage imageNamed:@"settingsDark.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"settingsLight.png"]];
    
}
- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(void)viewDidAppear:(BOOL)animated
{
    if ([self.videoCamera running])
        [self.videoCamera stop];
    
    [self.videoCamera start];
}


-(void)viewDidDisappear:(BOOL)animated{
    if ([self.videoCamera running])
        [self.videoCamera stop];
}
-(void)viewWillAppear:(BOOL)animated{
    //set the tabbar icons
    [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"scanDark.png"]withFinishedUnselectedImage:[UIImage imageNamed:@"scanLight.png"]];
    
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
    //cvtColor(image, image, CV_RGBA2BGR);
    
    //display scan area.
    Scalar scanAreaColor = Scalar(0, 255, 0);
    [self displayRectOnImage:image withColor:scanAreaColor];

    //select image segement to be processed for marker detection.
    cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
    Mat markerImage(image,markerRect);
    
    //apply threshold
    Mat thresholdedImage = [self applythresholdOnImage:markerImage];
    
    //find contours
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    findContours(thresholdedImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

    thresholdedImage.release();
    
    //detect markers
    NSDictionary* markers = [self detectMarkersForImageHierarchy:hierarchy andImageContour:contours];
    
    if (markers.count > 0){
        Scalar scanAreaColor = Scalar(0, 0, 255);
        [self displayRectOnImage:image withColor:scanAreaColor];
        
        [self processDetectionModeWithMakrers:markers withContours:contours andHierarchy:hierarchy];
    }
    
    markerImage.release();
}


-(Mat)applythresholdOnImage:(Mat)image{
    Mat thresholdedImage;
    //convert image to gray before applying the threshold.
    cvtColor(image, thresholdedImage, CV_BGRA2GRAY);
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

-(void)processDetectionModeWithMakrers:(NSDictionary*)markers withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy
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
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.videoCamera running]){
                    [self.videoCamera stop];
                }
                DtouchMarker* marker = [temporalMarkers guessMarker];
                [temporalMarkers resetTemporalMarker];
                [self displayWebViewControllerForMarker:marker];
            });
        }
    }
}

-(void)displayWebViewControllerForMarker:(DtouchMarker*)dtouchMarker{
    WebViewController *webViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    webViewController.marker = dtouchMarker;
    [self presentViewController:webViewController animated:YES completion:nil];
}

@end
