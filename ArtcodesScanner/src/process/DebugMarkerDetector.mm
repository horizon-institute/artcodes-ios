/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import "DebugMarkerDetector.h"
#import <vector>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>
#import <artcodesScanner/artcodesScanner-Swift.h>
#import "SceneDetails.h"
#import "ImageBuffers.h"

int const CHILD_NODE_INDEX = 2;
int const NEXT_SIBLING_NODE_INDEX = 0;



@implementation DebugMarkerDetectorFactory

-(NSString*) name
{
	return @"detectDebug";
}

-(id<ImageProcessor>) createWithSettings:(DetectionSettings*)settings arguments:(NSDictionary*)args
{
	return [[DebugMarkerDetector alloc] initWithSettings:settings];
}

@end

@implementation DebugMarkerDetector

- (id)initWithSettings:(DetectionSettings*)settings
{
	if (self = [super init])
	{
		self.settings = settings;
		return self;
	}
	return nil;
}

-(bool) requiresBgraInput
{
	return false;
}

-(void) process:(ImageBuffers*) buffers
{
	std::vector<std::vector<cv::Point> > contours;
	std::vector<cv::Vec4i> hierarchy;
	cv::findContours(buffers.imageInGrey, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
	
	// This autoreleasepool prevents memory allocated in [self findMarkers] from leaking.
	@autoreleasepool {
		//detect markers
		NSArray<Marker*>* markers = [self findMarkers:hierarchy andImageContour:contours andBuffers:buffers];
		
		self.settings.detected = markers.count > 0;
		if(self.settings.handler != nil)
		{
			[self.settings.handler onMarkersDetected:markers scene:[[SceneDetails alloc] initWithContours:contours hierarchy:hierarchy sourceImageSize:[[ImageSize alloc] initWithMat:buffers.imageInGrey]]];
		}
	}
}

-(NSArray<Marker*>*)findMarkers:(std::vector<cv::Vec4i>&)hierarchy andImageContour:(std::vector<std::vector<cv::Point> >&)contours andBuffers:(ImageBuffers*) buffers
{
	/*! Detected markers */
	NSMutableArray<Marker*>* markers = [[NSMutableArray alloc] init];
	//int skippedContours = 0;
	
	//NSLog(@"Contours %lu", contours.size());
	DetectionStatus status[contours.size()];
	for (int i = 0; i < contours.size(); i++)
	{
		//if (contours[i].size() < self.cameraSettings.minimumContourSize)
		//{
		//	++skippedContours;
		//	continue;
		//}
		
		status[i] = DetectionStatus_unknown;
		Marker* marker = [self createMarkerForNode:i imageHierarchy:hierarchy andImageContour:contours returnStatus:status+i];
		if (marker != nil)
		{
			NSString* markerKey = [self getCodeKey:marker];
			if(self.settings.validCodes.count == 0 || [self.settings.validCodes containsObject:markerKey])
			{
				[markers addObject: marker];
				
				[self drawMarker:markerKey atIndex:i onOverlay:buffers.overlay withContours:contours andHierarchy:hierarchy];
			}
		}
	}
	
	cv::Mat overlay = buffers.overlay;
	[self drawDebugViewForImage:overlay withDetectionStatus:status contours:contours andHierarchy:hierarchy];
	
	//NSLog(@"Skipped contours: %d/%lu",skippedContours,contours.size());
	return markers;
}

-(NSString*)getCodeKey:(Marker*)marker
{
	NSMutableString* codeStr = [[NSMutableString alloc] init];
	
	for (int i = 0; i < marker.regions.count; i++)
	{
		if(i != 0)
		{
			[codeStr appendString:@":"];
		}
		[codeStr appendFormat:@"%ld", (long)[marker.regions objectAtIndex:i].value];
	}
	
	return codeStr;
}

-(Marker*)createMarkerForNode:(int)nodeIndex imageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy andImageContour:(std::vector<std::vector<cv::Point> >&)contours returnStatus:(DetectionStatus*)status
{
	NSMutableArray* regions = nil;
	
	// Loop through the regions, verifing the value of each:
	for (int currentRegionIndex = imageHierarchy.at(nodeIndex)[CHILD_NODE_INDEX]; currentRegionIndex >= 0; currentRegionIndex = imageHierarchy.at(currentRegionIndex)[NEXT_SIBLING_NODE_INDEX])
	{
		MarkerRegion* region = [self createRegionForNode:currentRegionIndex inImageHierarchy:imageHierarchy returnStatus:status];
		if(region != nil)
		{
			if (self.settings.ignoreEmptyRegions && region.value==0)
			{
				continue;
			}
			else if(regions == nil)
			{
				regions = [[NSMutableArray alloc] init];
			}
			else if(regions.count >= self.settings.maxRegions)
			{
				// Too many regions.
				status[0] = DetectionStatus_numberOfRegions;
				return nil;
			}
			[regions addObject:region];
		}
		else
		{
			return nil;
		}
	}
	
	if (regions != nil)
	{
		[self sortRegions:regions];
		Marker* marker = [[Marker alloc] initWithIndex:nodeIndex regions:regions];
		if([self isValidRegionList:marker returnStatus:status])
		{
			status[0] = DetectionStatus_OK;
			return marker;
		}
	}
	return nil;
}

-(void)sortRegions:(NSMutableArray*) regions
{
	[regions sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]]];
}

-(BOOL)isValidRegionList:(Marker*) marker returnStatus:(DetectionStatus*)status
{
	if (marker == nil || marker.regions == nil)
	{
		// No Code
		status[0] = DetectionStatus_noSubContours;
		return false;
	}
	else if (marker.regions.count < self.settings.minRegions)
	{
		// Too Short
		status[0] = DetectionStatus_numberOfRegions;
		return false;
	}
	else if (marker.regions.count > self.settings.maxRegions)
	{
		// Too long
		status[0] = DetectionStatus_numberOfRegions;
		return false;
	}
	
	int numberOfEmptyRegions = 0;
	for (MarkerRegion* region in marker.regions)
	{
		//check if leaves are using in accepted range.
		if (region.value > self.settings.maxRegionValue)
		{
			status[0] = DetectionStatus_numberOfDots;
			return false; // value is too Big
		}
		else if (region.value==0 && ++numberOfEmptyRegions>self.settings.maxEmptyRegions)
		{
			status[0] = DetectionStatus_tooManyEmptyRegions;
			return false; // too many empty regions
		}
	}
	
	return [self hasValidChecksum:marker returnStatus:status];
}

-(BOOL)hasValidChecksum:(Marker*) marker returnStatus:(DetectionStatus*)status
{
	if (self.settings.checksum <= 1)
	{
		return true;
	}
	int numberOfLeaves = 0;
	for (MarkerRegion* region in marker.regions)
	{
		numberOfLeaves += region.value;
	}
	if ((numberOfLeaves % self.settings.checksum) == 0)
	{
		return true;
	}
	else
	{
		status[0] = DetectionStatus_checksum;
		return false;
	}
}

-(MarkerRegion*)createRegionForNode:(int)regionIndex inImageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy returnStatus:(DetectionStatus*)status
{
	// Find the first dot index:
	cv::Vec4i nodes = imageHierarchy.at(regionIndex);
	int currentDotIndex = nodes[CHILD_NODE_INDEX];
	if (currentDotIndex < 0 && !(self.settings.ignoreEmptyRegions || self.settings.maxEmptyRegions>0))
	{
		// There are no dots, and empty regions are not allowed.
		status[0] = DetectionStatus_tooManyEmptyRegions;
		return nil;
	}
	
	// Count all the dots and check if they are leaf nodes in the hierarchy:
	int dotCount = 0;
	while (currentDotIndex >= 0)
	{
		if ([self isValidLeaf:currentDotIndex inImageHierarchy:imageHierarchy])
		{
			dotCount++;
			// Get the next dot index:
			nodes = imageHierarchy.at(currentDotIndex);
			currentDotIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			
			if (dotCount > self.settings.maxRegionValue)
			{
				// Too many dots
				status[0] = DetectionStatus_numberOfDots;
				return nil;
			}
		}
		else
		{
			// Not a leaf
			status[0] = DetectionStatus_nestedRegions;
			return nil;
		}
	}
	
	return [[MarkerRegion alloc] initWithIndex:regionIndex value:dotCount];
}

-(bool)isValidLeaf:(int)nodeIndex inImageHierarchy:(std::vector<cv::Vec4i>&)imageHierarchy
{
	cv::Vec4i nodes = imageHierarchy.at(nodeIndex);
	return nodes[CHILD_NODE_INDEX] < 0;
}

-(void)drawMarker:(NSString*)marker atIndex:(int)index onOverlay:(cv::Mat) overlay withContours:(std::vector<std::vector<cv::Point>>)contours andHierarchy:(std::vector<cv::Vec4i>)hierarchy
{
	//color to draw contours
	cv::Scalar markerColor = cv::Scalar(0, 255, 255, 255);
	cv::Scalar regionColor = cv::Scalar(0, 128, 255, 255);
	cv::Scalar outlineColor = cv::Scalar(0, 0, 0, 255);
	
	if(self.settings.displayOutline > 0)
	{
		cv::Vec4i nodes = hierarchy.at(index);
		int currentRegionIndex= nodes[CHILD_NODE_INDEX];
		// Loop through the regions, verifing the value of each:
		if(self.settings.displayOutline == 2)
		{
			while (currentRegionIndex >= 0)
			{
				cv::drawContours(overlay, contours, currentRegionIndex, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
				cv::drawContours(overlay, contours, currentRegionIndex, regionColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
				
				// Get next region:
				nodes = hierarchy.at(currentRegionIndex);
				currentRegionIndex = nodes[NEXT_SIBLING_NODE_INDEX];
			}
		}
		
		cv::drawContours(overlay, contours, index, outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
		cv::drawContours(overlay, contours, index, markerColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
	}
	
	// draw code:
	if(self.settings.displayText == 1)
	{
		cv::Rect markerBounds = boundingRect(contours[index]);
		markerBounds.x = markerBounds.x;
		markerBounds.y = markerBounds.y;
		
		cv::putText(overlay, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(overlay, marker.fileSystemRepresentation, markerBounds.tl(), cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
	}
}



// Debug methods:

-(cv::Scalar)getColorForStatus:(DetectionStatus)status
{
	switch (status) {
		case DetectionStatus_tooManyEmptyRegions:
			return cv::Scalar(255*0, 255*0, 255*1, 255);		//red		tooManyEmptyRegions
		case DetectionStatus_nestedRegions:
			return cv::Scalar(255*0, 255*0.75, 255*1, 255);		//orange	nestedRegions
		case DetectionStatus_numberOfRegions:
			return cv::Scalar(255*0, 255*1, 255*1, 255);		//yellow	numberOfRegions
		case DetectionStatus_numberOfDots:
			return cv::Scalar(255*0, 255*1, 255*0, 255);		//green		numberOfDots
		case DetectionStatus_checksum:
			return cv::Scalar(255*1, 255*1, 255*0, 255);		//cyan		checksum
		case DetectionStatus_validationRegions:
			return cv::Scalar(255*1, 255*0, 255*0, 255);		//blue		validationRegions
		case DetectionStatus_extensionSpecificError:
			return cv::Scalar(255*1, 255*0, 255*0.75, 255);		//purple	extensionSpecificError
		case DetectionStatus_OK:
			return cv::Scalar(255*1, 255*0, 255*1, 255);		//violet	OK
		default:
			return cv::Scalar(0,0,0,0);
	}
}

NSArray *const DEBUG_MESSAGES = @[
								  @[@"unknown"],
								  @[@"No sub-contours"],
								  @[@"Too many empty regions", @"There must not be more than %d empty regions"],
								  @[@"Nested regions", @"Nested regions shown in red"],
								  @[@"Wrong number of regions", @"There must be %@ regions, check no lines are broken"],
								  @[@"Wrong number of dots", @"There must be a maximum of %d dots in each region"],
								  @[@"Does not match checksum", @"Check the number of dots or checksum setting"],
								  @[@"Does not match validation regions", @"Check number of dots found"],
								  @[@"Extension specific error"],
								  @[@"Marker found"]
								  ];

-(NSArray*)getMessagesForStatus:(DetectionStatus)status
{
	if (status==DetectionStatus_tooManyEmptyRegions)
	{
		return @[DEBUG_MESSAGES[status][0], [NSString stringWithFormat:DEBUG_MESSAGES[status][1], self.settings.maxEmptyRegions]];
	}
	else if (status==DetectionStatus_numberOfRegions)
	{
		return @[DEBUG_MESSAGES[status][0], [NSString stringWithFormat:DEBUG_MESSAGES[status][1], (self.settings.minRegions==self.settings.maxRegions ? [NSString stringWithFormat:@"%ld", (long)self.settings.minRegions] : [NSString stringWithFormat:@"%ld to %ld", (long)self.settings.minRegions, (long)self.settings.maxRegions])]];
	}
	else if (status==DetectionStatus_numberOfDots)
	{
		return @[DEBUG_MESSAGES[status][0], [NSString stringWithFormat:DEBUG_MESSAGES[status][1], self.settings.maxRegionValue]];
	}
	else
	{
		return DEBUG_MESSAGES[status];
	}
	
}

-(void)drawDebugForContourIndex:(int)contourIndex detectionStatus:(DetectionStatus)status image:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy
{
	cv::drawContours(image, contours, contourIndex, [self getColorForStatus:status], CV_FILLED, 8, hierarchy, 1, cv::Point(0, 0));
	
	
	if (status==DetectionStatus_tooManyEmptyRegions || status==DetectionStatus_nestedRegions || status==DetectionStatus_numberOfRegions || status==DetectionStatus_numberOfDots || status==DetectionStatus_checksum || status==DetectionStatus_validationRegions)
	{
		int regionCount = 0, dotTotal = 0;
		for (int regionIndex = hierarchy.at(contourIndex)[2]; regionIndex>-1 && regionCount<self.settings.maxRegions*10; regionIndex = hierarchy.at(regionIndex)[0])
		{
			int dotCount = 0;
			int firstDotIndex = hierarchy.at(regionIndex)[2];
			for (int dotIndex = firstDotIndex; dotIndex>-1 && dotCount<self.settings.maxRegionValue*10; dotIndex = hierarchy.at(dotIndex)[0])
			{
				++dotCount;
				if (status==DetectionStatus_nestedRegions && hierarchy.at(dotIndex)[2] != -1) // if dot has children it is nested
				{
					int nestedDotCount = 0;
					for (int nestedDotIndex=hierarchy.at(dotIndex)[2]; nestedDotIndex>-1; nestedDotIndex = hierarchy.at(nestedDotIndex)[0])
					{
						++nestedDotCount;
					}
					
					cv::drawContours(image, contours, dotIndex, (nestedDotCount==1 ? cv::Scalar(0,0,255,255) : cv::Scalar(255,0,0,255)), CV_FILLED, 8, hierarchy, 1, cv::Point(0, 0));
					
					cv::Point labelPoint = contours.at(dotIndex).at(0);
					NSString* str = [NSString stringWithFormat:@"%d", nestedDotCount];
					cv::putText(image, str.fileSystemRepresentation, labelPoint, cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0,0,0,255), 2);
					cv::putText(image, str.fileSystemRepresentation, labelPoint, cv::FONT_HERSHEY_SIMPLEX, 0.5, [self getColorForStatus:status], 1);
				}
				if (status==DetectionStatus_nestedRegions && hierarchy.at(dotIndex)[2] == -1) // dot has no children
				{
					cv::drawContours(image, contours, dotIndex, cv::Scalar(0,255,0,255), CV_FILLED, 8, hierarchy, 1, cv::Point(0, 0));
				}
			}
			dotTotal += dotCount;
			
			cv::Point labelPoint = contours.at(regionIndex).at(0);
			if (firstDotIndex > -1)
			{
				labelPoint = contours.at(firstDotIndex).at(0);
			}
			
			NSString* str = nil;
			if (!(self.settings.ignoreEmptyRegions && dotCount==0))
			{
				if (status==DetectionStatus_numberOfRegions || (status==DetectionStatus_tooManyEmptyRegions && dotCount==0))
				{
					str = [NSString stringWithFormat:@"%d", ++regionCount];
				}
				else if (status==DetectionStatus_numberOfDots || status==DetectionStatus_checksum || status==DetectionStatus_validationRegions)
				{
					str = [NSString stringWithFormat:@"%d", dotCount];
				}
			}
			
			if (str!=nil)
			{
				cv::putText(image, str.fileSystemRepresentation, labelPoint, cv::FONT_HERSHEY_SIMPLEX, 0.5, cv::Scalar(0,0,0,255), 3);
				cv::putText(image, str.fileSystemRepresentation, labelPoint, cv::FONT_HERSHEY_SIMPLEX, 0.5, [self getColorForStatus:status], 2);
			}
		}
	}
}


-(void)drawDebugViewForImage:(cv::Mat&)image withDetectionStatus:(DetectionStatus*)detectionStatus contours:(cv::vector<cv::vector<cv::Point> >)contours andHierarchy:(cv::vector<cv::Vec4i>)hierarchy
{
	if (hierarchy.size()==0)
	{
		return;
	}
	
	// setup buckets to place contour indexes in depending on their status
	const int numOfBuckets = 10;
	NSMutableArray* buckets = [[NSMutableArray alloc] init];
	for (int i=0; i<numOfBuckets; ++i)
	{
		[buckets addObject:[[NSMutableArray alloc] init]];
	}
	
	// label contours by depth in the hierarchy, white contours are even black contours are odd
	// this is so we can only process black contours as the display can look confusing if you have the same error on nested contours (and officially an Artcodes hierarchy should be black-white-black).
	int depth[contours.size()];
	[DebugMarkerDetector labelDepthOfContourHierarchy:hierarchy in:depth withRootIndex:0 andRootValue:0];
	
	// Place (black/odd) contours in buckets by error type
	for (int i=0; i<contours.size(); ++i)
	{
		if (depth[i]%2==0 || contours.at(i).size() < 50)
		{
			continue;
		}
		[buckets[detectionStatus[i]] addObject:@(i)];
	}
	
	
	// draw contours with highest level error status
	for (DetectionStatus status = DetectionStatus_OK; status!=DetectionStatus_noSubContours; status=[DebugMarkerDetector decrease:status])
	{
		if ([((NSArray*)buckets[status]) count] > 0)
		{
			for (NSNumber* contour in buckets[status])
			{
				[self drawDebugForContourIndex:[contour intValue] detectionStatus:status image:image withContours:contours andHierarchy:hierarchy];
			}
			
			cv::Scalar colour = [self getColorForStatus:status];
			
			NSArray* debugMessages = [self getMessagesForStatus:status];
			
			if ([debugMessages count]>=1 && ![debugMessages[0] isEqualToString:@""])
			{
				// print text message:
				NSString* str = debugMessages[0];
				
				double fontScaleStep = 0.1;
				double fontScale = 1 + fontScaleStep;
				int fontThickness = 2, baseLine = 0, textWidth = image.cols+1;
				while (textWidth > image.cols) { // decrease font scale until the text fits in the image
					fontScale -= fontScaleStep;
					cv::Size size = cv::getTextSize(str.fileSystemRepresentation, cv::FONT_HERSHEY_SIMPLEX, fontScale, fontThickness, &baseLine);
					textWidth = size.width;
				}
				int xPositionOfCentredText = (image.cols-textWidth)/2;
				int yPositionOfCentredText = image.rows - 40;
				
				cv::putText(image, str.fileSystemRepresentation, cv::Point(xPositionOfCentredText, yPositionOfCentredText), cv::FONT_HERSHEY_SIMPLEX, fontScale, cv::Scalar(0,0,0,255), fontThickness+5);
				cv::putText(image, str.fileSystemRepresentation, cv::Point(xPositionOfCentredText, yPositionOfCentredText), cv::FONT_HERSHEY_SIMPLEX, fontScale, colour, fontThickness);
				
				if ([debugMessages count]>=2 && ![debugMessages[1] isEqualToString:@""])
				{
					// print secondary message
					str = debugMessages[1];
					fontScale = 0.7 + fontScaleStep;
					fontThickness = 2;
					textWidth = image.cols+1;
					while (textWidth > image.cols) { // decrease font scale until the text fits in the image
						fontScale -= fontScaleStep;
						cv::Size size = cv::getTextSize(str.fileSystemRepresentation, cv::FONT_HERSHEY_SIMPLEX, fontScale, fontThickness, &baseLine);
						textWidth = size.width;
					}
					xPositionOfCentredText = (image.cols-textWidth)/2;
					yPositionOfCentredText = image.rows - 10;
					
					cv::putText(image, str.fileSystemRepresentation, cv::Point(xPositionOfCentredText, yPositionOfCentredText), cv::FONT_HERSHEY_SIMPLEX, fontScale, cv::Scalar(0,0,0,255), fontThickness+5);
					cv::putText(image, str.fileSystemRepresentation, cv::Point(xPositionOfCentredText, yPositionOfCentredText), cv::FONT_HERSHEY_SIMPLEX, fontScale, colour, fontThickness);
				}
			}
			
			break;
		}
	}
}


+(void)labelDepthOfContourHierarchy:(const cv::vector<cv::Vec4i>&)hierarchy in:(int*)depthArray withRootIndex:(int)rootIndex andRootValue:(int)rootValue
{
	int CV_NEXT=0, CV_CHILD=2;
	
	for (int i=rootIndex; i>-1 && i<hierarchy.size(); i=hierarchy.at(i)[CV_NEXT])
	{
		// label given node
		depthArray[i] = rootValue;
		// label children
		[DebugMarkerDetector labelDepthOfContourHierarchy:hierarchy in:depthArray withRootIndex:hierarchy.at(i)[CV_CHILD] andRootValue:rootValue+1];
	}
}

+(DetectionStatus)decrease:(DetectionStatus)status
{
	switch (status) {
		case DetectionStatus_OK:
			return DetectionStatus_extensionSpecificError;
		case DetectionStatus_extensionSpecificError:
			return DetectionStatus_validationRegions;
		case DetectionStatus_validationRegions:
			return DetectionStatus_checksum;
		case DetectionStatus_checksum:
			return DetectionStatus_numberOfDots;
		case DetectionStatus_numberOfDots:
			return DetectionStatus_numberOfRegions;
		case DetectionStatus_numberOfRegions:
			return DetectionStatus_nestedRegions;
		case DetectionStatus_nestedRegions:
			return DetectionStatus_tooManyEmptyRegions;
		case DetectionStatus_tooManyEmptyRegions:
			return DetectionStatus_noSubContours;
		case DetectionStatus_noSubContours:
			return DetectionStatus_unknown;
		case DetectionStatus_unknown:
			return DetectionStatus_unknown;
		default:
			return DetectionStatus_unknown;
	}
}

@end
