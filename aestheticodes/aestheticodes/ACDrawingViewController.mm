//
//  ACDrawingViewController.m
//  aestheticodes
//
//  Created by horizon on 23/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//
//
//  ACFirstViewController.m
//  aestheticodes
//
//  Created by horizon on 17/07/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "ACDrawingViewController.h"
#import "MarkerDetector.h"
#import "DtouchMarker.h"
#import "MarkerConstraint.h"
#import "TemporalMarkers.h"
#import "WebViewController.h"


@interface ACDrawingViewController (){
    cv::Rect markerRect;
    Mat *inputImage;
    
}

@end

@implementation ACDrawingViewController

@synthesize videoCamera;
@synthesize imageView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS =  10;
    self.videoCamera.grayscaleMode = YES;
    
}

-(void)viewDidAppear:(BOOL)animated
{
//    if ([self.videoCamera running])
//        [self.videoCamera stop];
//    if (![self.videoCamera running])
//        [self.videoCamera start];
    
    if ([self.videoCamera running])
        [self.videoCamera stop];
    
    [self.videoCamera start];
}
- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
-(void)viewWillAppear:(BOOL)animated{
    //set the tabbar icons
    [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"drawingDark.png"]withFinishedUnselectedImage:[UIImage imageNamed:@"drawingLight.png"]];
    
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
    
    inputImage = &image;
    
    markerRect = [self calculateMarkerImageSegmentArea:image];
    //display scan area.
    Scalar scanAreaColor = Scalar(0, 0, 0);
    [self displayRectOnImage:*inputImage withColor:scanAreaColor];
    
    //select image segement to be processed for marker detection.
    Mat markerImage(*inputImage,markerRect);
    
    //apply threshold
    Mat thresholdedImage = [self applythresholdOnImage:markerImage];
    
    //copy thresholded image to main image for drawing mode.
    thresholdedImage.copyTo(markerImage);

    //find contours
    vector<vector<cv::Point>> contours;
    vector<Vec4i> hierarchy;
    //findContours(contouredImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    findContours(thresholdedImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    //detect markers
    NSDictionary* markers = [self detectMarkersForImageHierarchy:hierarchy andImageContour:contours];
    
    if (markers.count > 0){
        [self processDrawingModeWithMarkers:markers forImage:markerImage withContours:contours andHierarchy:hierarchy];
    }
    
    thresholdedImage.release();
    markerImage.release();
    inputImage = nil;
    
}


-(Mat)applythresholdOnImage:(Mat)image{
    Mat thresholdedImage = image.clone();
    //apply threshold.
    adaptiveThreshold(thresholdedImage, thresholdedImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 91, 2);
    //threshold(thresholdedImage, thresholdedImage, 0, 255, CV_THRESH_OTSU);
    return thresholdedImage;
}

-(NSDictionary*)detectMarkersForImageHierarchy:(vector<Vec4i>)hierarchy andImageContour:(vector<vector<cv::Point>>)contours{
    MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:hierarchy imageContours:contours];
    return [markerDetector findMarkers];
}


-(void)displayContoursForMarkers:(NSDictionary*)markers forMarkerImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy markerRect:(cv::Rect)markerRect{
    
    //color to draw contours
    Scalar markerColor = Scalar(0, 0, 0);
    
    for (NSString *markerCode in markers){
        DtouchMarker *marker = [markers objectForKey:markerCode];
        for (NSNumber *nodeIndex in [marker getNodeIndexes]){
            drawContours(image, contours, [nodeIndex integerValue], markerColor, 3, 8, hierarchy, 0);
            [self displayCodeForMarker:marker];
        }
        
    }
}

//Style for the code that is displayed
-(void)displayCodeForMarker:(DtouchMarker*)marker{
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
        
        //cv::putText(*inputImage, text, textOrg, FONT_HERSHEY_PLAIN, 1.5, textColor, 2, 8, false);
        
        cv::putText(*inputImage, text, textOrg, FONT_HERSHEY_PLAIN, 1.5, textColor, 3, 8, false);
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

-(cv::Rect)calculateMarkerArea{
    CGSize size = self.imageView.frame.size;
    
    int imgWidth = size.width * 0.50;
    int imgHeight = imgWidth;
    
    int x = (size.width - imgWidth) / 2;
    int y = (size.height - imgHeight) / 2;
    
    return cv::Rect(x, y, imgWidth, imgHeight);
}

-(void)displayRectOnImage:(Mat)image withColor:(Scalar)color{
    rectangle(image, markerRect, color, 3);
}

-(void)processDrawingModeWithMarkers:(NSDictionary*)markers forImage:(Mat&)markerImage withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy{
    
    if (markers.count > 0 )
    {
        [self displayContoursForMarkers:markers forMarkerImage:markerImage withContours:contours andHierarchy:hierarchy markerRect:markerRect];
    }
}

@end
