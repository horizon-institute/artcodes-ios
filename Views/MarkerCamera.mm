//
//  ACCamera.mm
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Marker.h"
#import "MarkerCamera.h"
#import "MarkerFoundDelegate.h"
#import "MarkerSettings.h"
#import <UIKit/UIKit.h>
#include <vector>
#include <opencv2/opencv.hpp>
#include "ACODESMachineUtil.h"

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

static int BRANCH_INVALID = -1;
static int BRANCH_EMPTY = 0;

///////////////////////////

typedef enum {
    resizeIPhone5,
    resizeIPhone4,
    tile,
    temporalTile
} ThresholdBehaviour;
ThresholdBehaviour thresholdBehaviour;

///////////////////////////


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

@interface MarkerCamera()
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (nonatomic) bool rearCamera;
@property (nonatomic) cv::Rect markerRect;
@property (nonatomic) cv::Mat processImage1;
@property (nonatomic) cv::Mat processImage2;
@property (nonatomic) cv::Mat outputImage1;
@property (nonatomic) cv::Mat outputImage2;
@property bool detecting;
@end

@implementation MarkerCamera : NSObject

-(id)init
{
	self = [super init];
	if (self)
	{
		self.rearCamera = true;
		self.detecting = false;
        
        // init mutex
        self.newFrameAvaliable = false;
        self.processingImage1 = true;
        self.frameLock = [[NSLock alloc] init];
        self.detectingLock = [[NSLock alloc] init];
	}
	return self;
}

- (void) start:(UIImageView*)imageView
{
    self.settings = [MarkerSettings settings];
    
	if(self.videoCamera == NULL)
	{
		self.videoCamera = [[CvVideoCameraMod alloc] initWithParentView:imageView];
		self.videoCamera.delegate = self;
		if(self.rearCamera)
		{
			self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
		}
		else
		{
			self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
		}
        
        if ([ACODESMachineUtil isIPhone4])
        {
            NSLog(@"Using iPhone 4 settings");
            self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
            self.videoCamera.defaultFPS = 10;
            self.singleThread = true;
            self.fullSizeViewFinder = false;
            self.raisedTopBorder = false;
        }
        else if ([ACODESMachineUtil isIPhone4S])
        {
            NSLog(@"Using iPhone 4S settings");
            self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
            // 4S can handle AVCaptureSessionPresetiFrame960x540 but gets memory warning :(
            self.videoCamera.defaultFPS = 10;
            self.singleThread = false;
            self.fullSizeViewFinder = true;
            self.raisedTopBorder = true;
        }
        else if ([ACODESMachineUtil isIPhone5Series])
        {
            NSLog(@"Using iPhone 5/5S settings");
            self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetiFrame960x540;
            self.videoCamera.defaultFPS = 20;
            self.singleThread = false;
            self.fullSizeViewFinder = true;
            self.raisedTopBorder = false;
        }
        else
        {
            NSLog(@"Using pre-iPhone 4 settings");
            self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
            self.videoCamera.defaultFPS = 10;
            self.singleThread = true;
            self.fullSizeViewFinder = false;
            self.raisedTopBorder = false;
        }
        
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
		self.videoCamera.grayscaleMode = NO;
		self.videoCamera.rotateVideo = false;
        
		[self.videoCamera unlockFocus];
        
        NSLog(@"Threshold Behaviour setting: %@",self.settings.thresholdBehaviour);
        if ([self.settings.thresholdBehaviour isEqualToString:@"tile"])
        {
            thresholdBehaviour = tile;
        }
        else if ([self.settings.thresholdBehaviour isEqualToString:@"temporalTile"])
        {
            thresholdBehaviour = temporalTile;
        }
        else if ([self.settings.thresholdBehaviour isEqualToString:@"resize"])
        {
            thresholdBehaviour = resizeIPhone5;
        }
        else
        {
            thresholdBehaviour = temporalTile;
        }
	}
	else
	{
		//[self stop];
	}
    
    
    [self.detectingLock lock];
	if(!self.detecting)
	{
		self.detecting = true;
		
		if (!self.singleThread)
        {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			while(self.detecting)
			{
                // Sleep until a new frame is available. TODO: Change to semaphore/lock/other...
                // This does not seem to increase performance but it does fix a bug where it reads the old frame when switching back to the app after detection.
                while (!self.newFrameAvaliable)
				{
                    sleep(0.1);
                }
				
				[self processFrame];
			}
		});
        }
	}
	[self.detectingLock unlock];
    self.firstFrame = true;
    /////

	[self.videoCamera start];
}

int framesSinceLastMarker = 0;
-(void) processFrame
{
    [self.frameLock lock];
    self.processingImage1 = !self.processingImage1;
    self.newFrameAvaliable = false;
    
    //apply threshold.
    cv::Mat processImage;
    cv::Mat outputImage;
    if(self.processingImage1)
    {
        processImage = self.processImage1;
        outputImage = self.outputImage1;
    }
    else
    {
        processImage = self.processImage2;
        outputImage = self.outputImage2;
    }
    [self.frameLock unlock];
    
    [self thresholdImage:processImage];
    
    //find contours
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::Mat thresholdImageClone;
    if ([self.mode isEqualToString:@"threshold"])
    {
        thresholdImageClone = processImage.clone();
    }
    
    cv::findContours(processImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    if (contours.size() > self.settings.maximumContoursPerFrame)
    {
        NSLog(@"Too many contours (%lu) - skipping frame", contours.size());
        return;
    }
    
    // This autoreleasepool prevents memory allocated in [self findMarkers] from leaking.
    @autoreleasepool{
        //detect markers
        NSDictionary* markers = [self findMarkers:hierarchy andImageContour:contours];
        
        if ([markers count] > 0) {
            framesSinceLastMarker = 0;
        } else {
            ++framesSinceLastMarker;
        }
        
        if([self.mode isEqualToString:@"outline"])
        {
            outputImage.setTo(cv::Scalar(0, 0, 0, 0));
            [self drawMarkerContours:markers forImage:outputImage withContours:contours andHierarchy:hierarchy];
            
        }
        else if([self.mode isEqualToString:@"threshold"])
        {
            cvtColor(thresholdImageClone, outputImage, CV_GRAY2RGBA);
            /////
            [self drawMarkerContours:markers forImage:outputImage withContours:contours andHierarchy:hierarchy];
            /////
        }
        else
        {
            if(self.markerDelegate != nil)
            {
                [self.markerDelegate markersFound:markers];
            }
        }
    }
    //image.release();
}

- (void) flip:(UIImageView*)imageView
{
	[self stop];
	self.rearCamera = !self.rearCamera;
	self.videoCamera = nil;
	[self start:imageView];
}

- (void) stop
{
    [self.detectingLock lock];
	self.detecting = false;
    [self.detectingLock unlock];
	if(self.videoCamera.running)
	{
		[self.videoCamera stop];
	}
}

#pragma mark - Protocol CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image
{
    /////
    
    if (self.firstFrame) {
        self.firstFrame=false;
		self.markerRect = [self calculateMarkerImageSegmentArea:image];
		self.processImage1 = cv::Mat(self.markerRect.width, self.markerRect.height, CV_8UC1);
		self.processImage2 = cv::Mat(self.markerRect.width, self.markerRect.height, CV_8UC1);
		self.outputImage1 = cv::Mat(self.markerRect.width, self.markerRect.height, CV_8UC4);
		self.outputImage2 = cv::Mat(self.markerRect.width, self.markerRect.height, CV_8UC4);
		self.outputImage1.setTo(cv::Scalar(0, 0, 0, 0));
		self.outputImage2.setTo(cv::Scalar(0, 0, 0, 0));
    }
    
	//select image segement to be processed for marker detection.
	cv::Mat temp(image, self.markerRect);
	
	[self.frameLock lock];
	if(self.processingImage1)
	{
		cvtColor(temp, self.processImage2, CV_BGRA2GRAY);
        //NSLog(@"Produce 2");
	}
	else
	{
		cvtColor(temp, self.processImage1, CV_BGRA2GRAY);
        //NSLog(@"Produce 1");
	}
	self.newFrameAvaliable = true;
	[self.frameLock unlock];
	
	if(![self.mode isEqualToString:@"detect"])
	{
		cv::Mat outputImage;
		if(self.processingImage1)
		{
			outputImage = self.outputImage2;
		}
		else
		{
			outputImage = self.outputImage1;
		}
		
		for (int y = 0; y < outputImage.rows; y++)
		{
			cv::Vec4b* src_pixel = temp.ptr<cv::Vec4b>(y);
			const cv::Vec4b* ovl_pixel = outputImage.ptr<cv::Vec4b>(y);
			for (int x = 0; x < outputImage.cols; x++, ++src_pixel, ++ovl_pixel)
			{
				double alpha = (*ovl_pixel).val[3] / 255.0;
				for (int c = 0; c < 3; c++)
				{
					(*src_pixel).val[c] = (uchar) ((*ovl_pixel).val[c] * alpha + (*src_pixel).val[c] * (1.0 -alpha));
				}
			}
		}
	}
    
    if (self.singleThread)
    {
        [self processFrame];
    }
}

int cumulativeFramesWithoutMarker=0;
-(void) thresholdImage:(cv::Mat) image
{
    if (framesSinceLastMarker > 2) ++cumulativeFramesWithoutMarker;
    
    switch (thresholdBehaviour) {
        case resizeIPhone5:
        {
            cv::Mat resized = cv::Mat();
            
            resize(image, resized, cv::Size(540, 540));
            
            cv::GaussianBlur(resized, resized, cv::Size(3, 3), 0);
            
            adaptiveThreshold(resized, resized, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 151, 5);
            
            resize(resized, image, cv::Size(image.cols, image.rows));
            break;
        }
        case resizeIPhone4:
        {
            cv::Mat resized = cv::Mat();
            
            resize(image, resized, cv::Size(320, 320));
            
            cv::GaussianBlur(resized, resized, cv::Size(5, 5), 0);
            
            adaptiveThreshold(resized, resized, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 91, 5);
            
            resize(resized, image, cv::Size(image.cols, image.rows));
            break;
        }
        case tile:
        case temporalTile:
        {
            cv::GaussianBlur(image, image, cv::Size(3, 3), 0);
            
            
            int numberOfTiles = 1;
            if (thresholdBehaviour==temporalTile) numberOfTiles = (cumulativeFramesWithoutMarker%9)+1;
            int tileHeight = (int) image.size().height / numberOfTiles;
            int tileWidth = (int) image.size().width / numberOfTiles;
            
            // Split image into tiles and apply threshold on each image tile separately.
            for (int tileRowCount = 0; tileRowCount < numberOfTiles; tileRowCount++)
            {
                int startRow = tileRowCount * tileHeight;
                int endRow;
                if (tileRowCount < numberOfTiles - 1)
                {
                    endRow = (tileRowCount + 1) * tileHeight;
                }
                else
                {
                    endRow = (int) image.size().height;
                }
                
                for (int tileColCount = 0; tileColCount < numberOfTiles; tileColCount++)
                {
                    int startCol = tileColCount * tileWidth;
                    int endCol;
                    if (tileColCount < numberOfTiles - 1)
                    {
                        endCol = (tileColCount + 1) * tileWidth;
                    }
                    else
                    {
                        endCol = (int) image.size().width;
                    }
                    
                    cv::Mat tileMat(image, cv::Range(startRow, endRow), cv::Range(startCol, endCol));
                    threshold(tileMat, tileMat, 127, 255, cv::THRESH_OTSU);
                    tileMat.release();
                }
            }
            break;
        }
    }
}

-(void)drawMarkerContours:(NSDictionary*)markers forImage:(cv::Mat)image withContours:(cv::vector<cv::vector<cv::Point>>)contours andHierarchy:(cv::vector<cv::Vec4i>)hierarchy
{
	//color to draw contours
	cv::Scalar markerColor = cv::Scalar(0, 255, 255, 255);
	cv::Scalar outlineColor = cv::Scalar(0, 0, 0, 255);
	
	cv::Rect rect = [self calculateMarkerImageSegmentArea:image];
	
	for (NSString *markerCode in markers)
	{
		Marker* marker = [markers objectForKey:markerCode];
		for (NSNumber *nodeIndex in marker.nodeIndexes)
		{
			cv::drawContours(image, contours, (int)[nodeIndex integerValue], outlineColor, 3, 8, hierarchy, 0, cv::Point(rect.x, rect.y));
			cv::drawContours(image, contours, (int)[nodeIndex integerValue], markerColor, 2, 8, hierarchy, 0, cv::Point(rect.x, rect.y));
		}
	}

	for(NSString *markerCode in markers)
	{
		Marker* marker = [markers objectForKey:markerCode];
		for (NSNumber *nodeIndex in marker.nodeIndexes)
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
    if (!self.fullSizeViewFinder)
    {
        size /= 1.4;
    }
	
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
    /*! Detected markers */
	NSMutableDictionary* markers = [[NSMutableDictionary alloc] init];
    int skippedContours = 0;
    
	for (int i = 0; i < contours.size(); i++)
	{
        if (contours[i].size() < self.settings.minimumContourSize)
        {
            ++skippedContours;
            continue;
        }
        /////
        
        
		NSArray* markerCode = [self createMarkerForNode:i imageHierarchy:hierarchy];
		NSString* markerKey = [Marker getCodeKey:markerCode];
		if (markerKey != nil)
		{
            NSLog(@"Found marker from contour of size %lu",contours[i].size());
			//if code is already detected.
			Marker *marker = [markers objectForKey:markerKey];
			if (marker != nil)
			{
				[marker.nodeIndexes addObject:[[NSNumber alloc] initWithInt:i]];
			}
			else
			{
				marker = [[Marker alloc] initWithCode:markerCode andKey:markerKey];
				[marker.nodeIndexes addObject:[[NSNumber alloc] initWithInt:i]];
				[markers setObject:marker forKey:marker.codeKey];
			}
		}
	}
    
    //NSLog(@"Skipped contours: %d/%lu",skippedContours,contours.size());
	return markers;
}


-(NSArray*)createMarkerForNode:(int)nodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	int currentBranchIndex;
	int numOfBranches = 0;
	int numOfEmptyBranches = 0;
	
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
			int regionCode = [self getCodeForNodeIndex:currentBranchIndex imageHierarchy:imageHierarchy];
			if (regionCode == BRANCH_EMPTY)
			{
				numOfEmptyBranches++;
				if(numOfEmptyBranches > self.settings.maxEmptyRegions)
				{
					return nil;
				}
			}
			
			if (regionCode != BRANCH_INVALID)
			{
				[markerCode addObject:[[NSNumber alloc] initWithInt:regionCode]];
				numOfBranches++;
				nodes = imageHierarchy.at(currentBranchIndex);
				currentBranchIndex = nodes[NEXT_SIBLING_NODE_INDEX];
				if(numOfBranches > self.settings.maxRegions)
				{
					return nil;
				}
			}
			else
			{
				break;
			}
		}
	}
	if ([self.settings isValid:markerCode])
	{
		return [markerCode sortedArrayUsingSelector: @selector(compare:)];
	}
	return nil;
}

-(int)getCodeForNodeIndex:(int)branchNodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	int currentLeafIndex;
	int leafCount = 0;
	
	cv::Vec4i nodes = imageHierarchy.at(branchNodeIndex);
	currentLeafIndex = nodes[CHILD_NODE_INDEX];
	//if there is a leaf node
	if (currentLeafIndex >= 0)
	{
		while (currentLeafIndex >= 0)
		{
			if ([self isValidLeaf:currentLeafIndex imageHierarchy:imageHierarchy])
			{
				leafCount++;
				nodes = imageHierarchy.at(currentLeafIndex);
				//get sibling of the leaf node.
				currentLeafIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
			else
			{
				return BRANCH_INVALID;
			}
		}
	}
	
	return leafCount;
}

-(bool)isValidLeaf:(int)leafNodeIndex imageHierarchy:(cv::vector<cv::Vec4i>)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(leafNodeIndex);
	//if leaf has child node
	return nodes[CHILD_NODE_INDEX] < 0;
}

@end