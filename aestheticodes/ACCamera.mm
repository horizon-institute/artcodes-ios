//
//  ACCamera.m
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACCamera.h"
#import <UIKit/UIKit.h>

@interface ACCamera()
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic, retain) UIImageView* imageView;
@end


@implementation ACCamera : NSObject

-(id)init:(UIImageView*)imageView
{
	self = [super init];
	self.imageView = imageView;
	self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
	self.videoCamera.delegate = self;
	self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
	self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	self.videoCamera.defaultFPS =  10;
	self.videoCamera.grayscaleMode = NO;
	
	return self;
}

- (void) start {
	[_videoCamera start];
}

- (void) stop {
	[_videoCamera stop];
}

- (BOOL) isRunning {
	return _videoCamera.running;
}

#pragma mark - Protocol CvVideoCameraDelegate

-(void)processImage:(Mat&)image
{
	//Remove alpha channel as draw functions dont use alpha channel if the image has 4 channels.
	//cvtColor(image, image, CV_RGBA2BGR);
	
	//display scan area.
	Scalar scanAreaColor = Scalar(0, 0, 0);
	Mat frame = image.clone();
	
	[self displayRectOnImage:frame withColor:scanAreaColor];
	
	double opacity = 0.6;
	addWeighted(frame, opacity, image, 1- opacity, 0, image);
	
	//select image segement to be processed for marker detection.
	cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
	Mat markerImage(image, markerRect);
	
	//apply threshold
	Mat thresholdedImage = [self applythresholdOnImage:markerImage];
	
	//find contours
	vector<vector<cv::Point>> contours;
	vector<Vec4i> hierarchy;
	findContours(thresholdedImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
	
	//detect markers
	NSDictionary* markers = [self detectMarkersForImageHierarchy:hierarchy andImageContour:contours];
	
	if (markers.count > 0)
	{
		switch(_drawMode)
		{
			case 0:
				[self processDetectionModeWithMarkers:markers withContours:contours andHierarchy:hierarchy];
				break;
			case 1:
				[self processDrawingModeWithMarkers:markers forImage:image withContours:contours andHierarchy:hierarchy];
				break;
				// Nothing
		}
	}
	
	thresholdedImage.release();
	markerImage.release();
}


-(Mat)applythresholdOnImage:(Mat)image
{
	Mat thresholdedImage;
	//convert image to gray before applying the threshold.
	cvtColor(image, thresholdedImage, CV_BGRA2GRAY);
	//apply threshold.
	adaptiveThreshold(thresholdedImage, thresholdedImage, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 91, 2);
	//threshold(thresholdedImage, thresholdedImage, 0, 255, CV_THRESH_OTSU);
	return thresholdedImage;
}

-(NSDictionary*)detectMarkersForImageHierarchy:(vector<Vec4i>)hierarchy andImageContour:(vector<vector<cv::Point>>)contours
{
	//MarkerDetector *markerDetector = [[MarkerDetector alloc] initWithImageHierarchy:hierarchy imageContours:contours];
	//return [markerDetector findMarkers];
	return NULL;
}


-(void)displayContoursForMarkers:(NSDictionary*)markers forMarkerImage:(Mat)image withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy
{
	
	//color to draw contours
	Scalar markerColor = Scalar(0, 0, 255);
	
	cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
	
	for (NSString *markerCode in markers)
	{
//		ACMarker *marker = [markers objectForKey:markerCode];
//		for (NSNumber *nodeIndex in [marker getNodeIndexes])
//		{
//			drawContours(image, contours, (int)[nodeIndex integerValue], markerColor, 2, 8, hierarchy, 0, cv::Point(rect.x, rect.y));
//			
//			cv::Rect markerBounds = boundingRect(contours[nodeIndex.integerValue]);
//			markerBounds.x = markerBounds.x + rect.x;
//			markerBounds.y = markerBounds.y + rect.y;
//			
//			putText(image, markerCode.fileSystemRepresentation, markerBounds.tl(), FONT_HERSHEY_SIMPLEX, 0.7, markerColor, 2);
//		}
	}
}

//calculate region in the image which is used for marker detection.
-(cv::Rect) calculateMarkerImageSegmentArea:(Mat)image
{
	int width = image.cols;
	int height = image.rows;
	
	int size = MIN(width, height);
	
	int x = (width - size) / 2;
	int y = (height - size) / 2;
	
	return cv::Rect(x, y, size, size);
}

-(void)displayRectOnImage:(Mat)image withColor:(Scalar)color
{
	cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
	
	int width = image.cols;
	int height = image.rows;
	
	rectangle(image, cv::Point(0,0), cv::Point(width, rect.y), color, CV_FILLED);
	rectangle(image, cv::Point(0, rect.y), cv::Point(rect.x, rect.y + rect.height), color, CV_FILLED);
	rectangle(image, cv::Point(rect.x + rect.width, rect.y), cv::Point(width, rect.y + rect.height), color, CV_FILLED);
	rectangle(image, cv::Point(0,rect.y + rect.height), cv::Point(width, height), color, CV_FILLED);
}

-(void)processDrawingModeWithMarkers:(NSDictionary*)markers forImage:(Mat&)markerImage withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy{
	
	if (markers.count > 0 )
	{
		[self displayContoursForMarkers:markers forMarkerImage:markerImage withContours:contours andHierarchy:hierarchy];
	}
}

-(void)processDetectionModeWithMarkers:(NSDictionary*)markers withContours:(vector<vector<cv::Point>>)contours andHierarchy:(vector<Vec4i>)hierarchy
{
	//cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
	if (markers.count > 0 )
	{
//		dispatch_async(dispatch_get_main_queue(), ^{
//			//started
//			if ([temporalMarkers hasIntegrationStarted])
//			{
//				[progressView setProgress:0.0];
//				progressView.hidden = false;
//			}
//			
//			float percent = [temporalMarkers getIntegrationPercent];
//			if (percent == 1.0)
//			{
//				progressView.hidden = true;
//			}
//			[progressView setProgress:percent animated:YES];
//		});
//		
//		//add markers into list
//		[temporalMarkers integrateMarkers:markers];
//		
//		if([temporalMarkers isMarkerDetectionTimeUp])
//		{
//			ACMarker* marker = [temporalMarkers guessMarker];
//			[temporalMarkers resetTemporalMarker];
//			camera.stop();
//			progressView.hidden = true;
//			NSString* markerUrl = [[[ACSettings getSettings] markers]objectForKey:marker.codeKey];
//			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:markerUrl]];
//		}
	}
}


//enum BranchStatus{
//	BRANCH_INVALID,
//	BRANCH_EMPTY,
//	BRANCH_VALID
//};
//
//@interface BranchCode : NSObject
//@property BranchStatus status;
//@property int leafCount;
//@end
//
//@implementation BranchCode
//@synthesize status;
//@synthesize leafCount;
//@end
//
//@interface MarkerDetector()
//@property vector<Vec4i> imageHierarchy;
//@property vector<vector<cv::Point>> imageContours;
//
//-(ACMarker*)newDtouchMarkerForNode:(int)nodeIndex;
//-(BranchCode*)newBranchCodeForNodeIndex:(int)branchNodeIndex;
//-(bool)isValidLeaf:(int)leafNodeIndex;
//@end
//
//@implementation MarkerDetector
//
//const int CHILD_NODE_INDEX = 2;
//const int NEXT_SIBLING_NODE_INDEX = 0;
//
//
//@synthesize imageHierarchy;
//@synthesize imageContours;
//
//-(id)initWithImageHierarchy:(vector<Vec4i>)inImageHierarchy imageContours:(vector<vector<cv::Point>>)inImageContours
//{
//	self = [super init];
//	
//	if (self){
//		imageHierarchy = inImageHierarchy;
//		imageContours = inImageContours;
//	}
//	return self;
//}
//
//-(NSDictionary*)findMarkers{
//	MarkerConstraint *markerConstraint = [[MarkerConstraint alloc] init];
//	NSMutableDictionary* dtouchCodes = [NSMutableDictionary dictionary];
//	for (int i = 0; i < imageContours.size(); i++)
//	{
//		ACMarker* newMarker = [self newDtouchMarkerForNode:i];
//		if (newMarker != nil && [markerConstraint isValidDtouchMarker:newMarker]){
//			//if code is already detected.
//			ACMarker *marker = [dtouchCodes objectForKey:newMarker.codeKey];
//			if (marker != nil){
//				[marker addNodeIndex:i];
//				
//			}else{
//				[dtouchCodes setObject:newMarker forKey:newMarker.codeKey];
//			}
//		}
//	}
//	return dtouchCodes;
//}
//
//-(ACMarker*)newDtouchMarkerForNode:(int)nodeIndex{
//	
//	int currentBranchIndex;
//	int numOfBranches = 0;
//	int numOfEmptyBranches = 0;
//	ACMarker* marker;
//	
//	NSMutableArray* markerCode = [[NSMutableArray alloc] init];
//	
//	//get the nodes of the root node.
//	Vec4i nodes = imageHierarchy.at(nodeIndex);
//	//get the first child node.
//	currentBranchIndex = nodes[CHILD_NODE_INDEX];
//	//if there is a branch node then verify branches.
//	if (currentBranchIndex >= 0){
//		//loop until there is a branch node.
//		while (currentBranchIndex >= 0){
//			BranchCode *branchCode = [self newBranchCodeForNodeIndex:currentBranchIndex];
//			if (branchCode.status == BRANCH_EMPTY)
//				numOfEmptyBranches++;
//			if (branchCode.status == BRANCH_VALID || branchCode.status == BRANCH_EMPTY){
//				[markerCode addObject:[[NSNumber alloc] initWithInt:branchCode.leafCount]];
//				numOfBranches++;
//				nodes = imageHierarchy.at(currentBranchIndex);
//				currentBranchIndex = nodes[NEXT_SIBLING_NODE_INDEX];
//			}
//			else if (branchCode.status == BRANCH_INVALID)
//				break;
//		}
//	}
//	if (markerCode.count > 0){
//		marker = [[ACMarker alloc] init];
//		[marker addNodeIndex:nodeIndex];
//		marker.code = markerCode;
//	}
//	return marker;
//}
//
//-(BranchCode*)newBranchCodeForNodeIndex:(int)branchNodeIndex
//{
//	int currentLeafIndex;
//	
//	BranchCode *branchCode = [[BranchCode alloc] init];
//	branchCode.status = BRANCH_INVALID;
//	branchCode.leafCount = 0;
//	
//	Vec4i nodes = imageHierarchy.at(branchNodeIndex);
//	currentLeafIndex = nodes[CHILD_NODE_INDEX];
//	//if there is a leaf node
//	if (currentLeafIndex >= 0)
//	{
//		while (currentLeafIndex >= 0){
//			if ([self isValidLeaf:currentLeafIndex]){
//				branchCode.leafCount++;
//				nodes = imageHierarchy.at(currentLeafIndex);
//				//get sibling of the leaf node.
//				currentLeafIndex = nodes[NEXT_SIBLING_NODE_INDEX];
//			}else{
//				branchCode.status = BRANCH_INVALID;
//				branchCode.leafCount = -1;
//				break;
//			}
//		}
//	}
//	if (branchCode.leafCount == 0){
//		branchCode.status = BRANCH_EMPTY;
//	}
//	else if (branchCode.leafCount > 0){
//		branchCode.status = BRANCH_VALID;
//	}
//	return branchCode;
//}
//
//-(bool)isValidLeaf:(int)leafNodeIndex
//{
//	bool valid = false;
//	Vec4i nodes = imageHierarchy.at(leafNodeIndex);
//	//if leaf has child node
//	if (nodes[CHILD_NODE_INDEX] >= 0){
//		valid = false;
//	}else
//		valid = true;
//	return valid;
//}
//

@end

