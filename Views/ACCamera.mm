//
//  ACCamera.mm
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACCamera.h"
#import <UIKit/UIKit.h>
#include <vector>
#include <opencv2/opencv.hpp>
#import "aestheticodes-Swift.h"

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

enum BranchStatus
{
	BRANCH_INVALID,
	BRANCH_EMPTY,
	BRANCH_VALID
};

@protocol CvVideoCameraDelegateMod <CvVideoCameraDelegate>
@end

@interface CvVideoCameraMod : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@end

@implementation CvVideoCameraMod

- (void)updateOrientation;
{
	self->customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
	[self layoutPreviewLayer];
}



- (void)layoutPreviewLayer;
{
	if (self.parentView != nil)
	{
		CALayer* layer = self->customPreviewLayer;
		CGRect bounds = self->customPreviewLayer.bounds;
		int rotation_angle = 0;
		
		switch (defaultAVCaptureVideoOrientation) {
			case AVCaptureVideoOrientationLandscapeRight:
				rotation_angle = 180;
				break;
			case AVCaptureVideoOrientationPortraitUpsideDown:
				rotation_angle = 270;
				break;
			case AVCaptureVideoOrientationPortrait:
				rotation_angle = 0;
			case AVCaptureVideoOrientationLandscapeLeft:
				break;
			default:
				break;
		}
		
		layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
		layer.affineTransform = CGAffineTransformMakeRotation( DEGREES_RADIANS(rotation_angle) );
		layer.bounds = bounds;
	}
}
@end

@interface BranchCode : NSObject
@property BranchStatus status;
@property int leafCount;
@end

@implementation BranchCode
@synthesize status;
@synthesize leafCount;
@end

@interface ACCamera()
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@end

@implementation ACCamera : NSObject

- (void) start:(UIImageView*)imageView
{
	if(self.videoCamera == NULL)
	{
		self.videoCamera = [[CvVideoCameraMod alloc] initWithParentView:imageView];
		self.videoCamera.delegate = self;
		self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
		self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
		self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
		self.videoCamera.defaultFPS = 10;
		self.videoCamera.grayscaleMode = NO;
		self.videoCamera.rotateVideo = false;
	}
	else
	{
		[self stop];
	}

	[self.videoCamera start];
}

- (void) stop
{
	if(self.videoCamera.running)
	{
		[self.videoCamera stop];
	}
}

#pragma mark - Protocol CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image
{
	//Remove alpha channel as draw functions dont use alpha channel if the image has 4 channels.
	cv::cvtColor(image, image, CV_RGBA2BGR);
	
	//select image segement to be processed for marker detection.
	cv::Rect markerRect = [self calculateMarkerImageSegmentArea:image];
	cv::Mat markerImage(image, markerRect);
	
	//apply threshold
	cv::Mat thresholdedImage = [self applythresholdOnImage:markerImage];
	
	//find contours
	cv::vector<cv::vector<cv::Point>> contours;
	cv::vector<cv::Vec4i> hierarchy;
	cv::findContours(thresholdedImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
	
	//detect markers
	NSDictionary* markers = [self findMarkers:hierarchy andImageContour:contours];
	if (markers.count > 0)
	{
		switch(self.drawMode)
		{
			case 0:
				if(self.markerDelegate != nil)
				{
					[self.markerDelegate markersFound:markers];
				}
				break;
			case 1:
				[self drawMarkerContours:markers forImage:image withContours:contours andHierarchy:hierarchy];
				break;
				// Nothing
		}
	}

	if(self.drawMode == 2)
	{
		thresholdedImage.copyTo(image);
	}
	
	thresholdedImage.release();
	markerImage.release();
}


-(cv::Mat)applythresholdOnImage:(cv::Mat&)image
{
	cv::Mat thresholdedImage;
	//convert image to gray before applying the threshold.
	cvtColor(image, thresholdedImage, CV_BGRA2GRAY);
	//apply threshold.
	adaptiveThreshold(thresholdedImage, thresholdedImage, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 91, 2);
	return thresholdedImage;
}

-(void)drawMarkerContours:(NSDictionary*)markers forImage:(cv::Mat)image withContours:(cv::vector<cv::vector<cv::Point>>)contours andHierarchy:(cv::vector<cv::Vec4i>)hierarchy
{
	//color to draw contours
	cv::Scalar markerColor = cv::Scalar(0, 255, 255);
	cv::Scalar outlineColor = cv::Scalar(0, 0, 0);
	
	cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
	
	for (NSString *markerCode in markers)
	{
		Marker *marker = [markers objectForKey:markerCode];
		for (NSNumber *nodeIndex in marker.nodeIndices)
		{
			cv::drawContours(image, contours, (int)[nodeIndex integerValue], outlineColor, 3, 8, hierarchy, 0, cv::Point(rect.x, rect.y));
			cv::drawContours(image, contours, (int)[nodeIndex integerValue], markerColor, 2, 8, hierarchy, 0, cv::Point(rect.x, rect.y));
		}
	}

	for(NSString *markerCode in markers)
	{
		Marker *marker = [markers objectForKey:markerCode];
		for (NSNumber *nodeIndex in marker.nodeIndices)
		{
			cv::Rect markerBounds = boundingRect(contours[nodeIndex.integerValue]);
			markerBounds.x = markerBounds.x + rect.x;
			markerBounds.y = markerBounds.y + rect.y;

			cv::putText(image, markerCode.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
			cv::putText(image, markerCode.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
		}
	}
}

//calculate region in the image which is used for marker detection.
-(cv::Rect) calculateMarkerImageSegmentArea:(cv::Mat&)image
{
	int width = image.cols;
	int height = image.rows;
	
	int size = MIN(width, height);
	
	int x = (width - size) / 2;
	int y = (height - size) / 2;
	
	return cv::Rect(x, y, size, size);
}

-(void)displayRectOnImage:(cv::Mat)image withColor:(cv::Scalar)color
{
	cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
	
	int width = image.cols;
	int height = image.rows;
	
	cv::rectangle(image, cv::Point(0,0), cv::Point(width, rect.y), color, CV_FILLED);
	cv::rectangle(image, cv::Point(0, rect.y), cv::Point(rect.x, rect.y + rect.height), color, CV_FILLED);
	cv::rectangle(image, cv::Point(rect.x + rect.width, rect.y), cv::Point(width, rect.y + rect.height), color, CV_FILLED);
	cv::rectangle(image, cv::Point(0,rect.y + rect.height), cv::Point(width, height), color, CV_FILLED);
}

const int CHILD_NODE_INDEX = 2;
const int NEXT_SIBLING_NODE_INDEX = 0;


-(NSDictionary*)findMarkers:(cv::vector<cv::Vec4i>)hierarchy andImageContour:(cv::vector<cv::vector<cv::Point>>)contours
{
	NSMutableDictionary* markers = [NSMutableDictionary dictionary];
	for (int i = 0; i < contours.size(); i++)
	{
		Marker* newMarker = [self createMarkerForNode:i imageHierarchy:hierarchy];
		if (newMarker != nil && [self.settings isValid:newMarker])
		{
			//if code is already detected.
			Marker *marker = [markers objectForKey:newMarker.codeKey];
			if (marker != nil)
			{
				[marker addNode:i];
			}
			else
			{
				[markers setObject:newMarker forKey:newMarker.codeKey];
			}
		}
	}
	return markers;
}


-(Marker*)createMarkerForNode:(int)nodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	int currentBranchIndex;
	int numOfBranches = 0;
	int numOfEmptyBranches = 0;
	Marker* marker;
	
	NSMutableArray* markerCode = [[NSMutableArray alloc] init];
	
	//get the nodes of the root node.
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	//get the first child node.
	currentBranchIndex = nodes[CHILD_NODE_INDEX];
	//if there is a branch node then verify branches.
	if (currentBranchIndex >= 0)
	{
		//loop until there is a branch node.
		while (currentBranchIndex >= 0)
		{
			BranchCode *branchCode = [self getCodeForNodeIndex:currentBranchIndex imageHierarchy:imageHierarchy];
			if (branchCode.status == BRANCH_EMPTY)
			{
				numOfEmptyBranches++;
			}
			if (branchCode.status == BRANCH_VALID || branchCode.status == BRANCH_EMPTY)
			{
				[markerCode addObject:[[NSNumber alloc] initWithInt:branchCode.leafCount]];
				numOfBranches++;
				nodes = imageHierarchy.at(currentBranchIndex);
				currentBranchIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
			else if (branchCode.status == BRANCH_INVALID)
			{
				break;
			}
		}
	}
	if (markerCode.count > 0)
	{
		marker = [[Marker alloc] init];
		[marker addNode:nodeIndex];
		
		marker.code = [markerCode sortedArrayUsingSelector: @selector(compare:)];
	}
	return marker;
}

-(BranchCode*)getCodeForNodeIndex:(int)branchNodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	int currentLeafIndex;
	
	BranchCode *branchCode = [[BranchCode alloc] init];
	branchCode.status = BRANCH_INVALID;
	branchCode.leafCount = 0;
	
	cv::Vec4i nodes = imageHierarchy.at(branchNodeIndex);
	currentLeafIndex = nodes[CHILD_NODE_INDEX];
	//if there is a leaf node
	if (currentLeafIndex >= 0)
	{
		while (currentLeafIndex >= 0)
		{
			if ([self isValidLeaf:currentLeafIndex imageHierarchy:imageHierarchy])
			{
				branchCode.leafCount++;
				nodes = imageHierarchy.at(currentLeafIndex);
				//get sibling of the leaf node.
				currentLeafIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
			else
			{
				branchCode.status = BRANCH_INVALID;
				branchCode.leafCount = -1;
				break;
			}
		}
	}
	
	if (branchCode.leafCount == 0)
	{
		branchCode.status = BRANCH_EMPTY;
	}
	else if (branchCode.leafCount > 0)
	{
		branchCode.status = BRANCH_VALID;
	}
	return branchCode;
}

-(bool)isValidLeaf:(int)leafNodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(leafNodeIndex);
	//if leaf has child node
	return nodes[CHILD_NODE_INDEX] < 0;
}

@end