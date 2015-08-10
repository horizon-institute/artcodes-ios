/*
 * Aestheticodes recognises a different marker scheme that allows the
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

#import "MarkerCodeAreaOrientationOrderExtensionFactory.h"

NSString *const REGION_AREA = @"area";
NSString *const REGION_LABEL = @"label";


@interface ACXLine : NSObject
@property double m;
@property double c;
@property double xAxisCrossPoint;
@property bool isVerticle;
@property bool isHorizontal;
@property bool pointsToXAxis;
@property bool pointsToYAxis;
-(ACXLine*)initWithStartPoint:(cv::Point)p1 andEndPoint:(cv::Point)p2;
-(ACXLine*)initWithPoint:(cv::Point)p andGradient:(double)m;
-(cv::Point)getIntersectionWith:(ACXLine*)otherLine;
-(double)getIntersectionBetweenXAxisAndParallelThrough:(cv::Point)p;
@end
@implementation ACXLine

-(ACXLine*)initWithStartPoint:(cv::Point)p1 andEndPoint:(cv::Point)p2
{
	self = [super init];
	self.isVerticle   = p1.x==p2.x;
	self.isHorizontal = p1.y==p2.y;
	self.pointsToXAxis = (p1.x < p2.x && p1.y > p2.y) || (p1.x > p2.x && p1.y > p2.y) || (p1.x == p2.x && p1.y > p2.y);
	self.pointsToYAxis = (p1.x > p2.x && p1.y < p2.y) || (p1.x > p2.x && p1.y > p2.y) || (p1.x > p2.x && p1.y == p2.y);
	if (!self.isHorizontal && !self.isVerticle)
	{
		self.m = ((double)p1.y-(double)p2.y)/((double)p1.x-(double)p2.x);
		// y=mx+c ... y-mx=c
		self.c = (double)p1.y-self.m*(double)p1.x;
	}
	else if (self.isHorizontal)
	{
		self.m = 0;
		self.c = (double)p1.y;
	}
	else if (self.isVerticle)
	{
		self.m = INFINITY;
		self.c = 0;
		self.xAxisCrossPoint = (double)p1.x;
	}
	return self;
}
-(ACXLine*)initWithPoint:(cv::Point)p andGradient:(double)m
{
	self = [super init];
	self.isHorizontal = m==0;
	self.isVerticle   = m==INFINITY;
	self.m = m;
	if (self.isVerticle)
	{
		self.xAxisCrossPoint = p.x;
		self.c = 0;
	}
	else if (self.isHorizontal)
	{
		self.c = (double)p.y;
	}
	else
	{
		self.c = (double)p.y-self.m*(double)p.x;
	}
	return self;
}
-(cv::Point)getIntersectionWith:(ACXLine*)otherLine
{
	if (self.m == otherLine.m)
	{
		return cv::Point(INFINITY,INFINITY);
	}
	else if (self.isVerticle || otherLine.isVerticle)
	{
		ACXLine *verticleLine = self.isVerticle ? self : otherLine;
		ACXLine *nonVerticleLine = self.isVerticle ? otherLine : self;
		
		if (nonVerticleLine.isHorizontal)
		{
			return cv::Point(verticleLine.xAxisCrossPoint, nonVerticleLine.c);
		}
		else
		{
			double x = verticleLine.xAxisCrossPoint;
			return cv::Point(x, nonVerticleLine.m*x+nonVerticleLine.c);
		}
	}
	else if (self.isHorizontal || otherLine.isHorizontal)
	{
		ACXLine *horizontalLine = self.isHorizontal ? self : otherLine;
		ACXLine *nonHorizontalLine = self.isHorizontal ? otherLine : self;
		
		double y = horizontalLine.c;
		return cv::Point((y-nonHorizontalLine.c)/nonHorizontalLine.m, y);
	}
	
	//m1x+c1 = m2x+c2 ... m1x-m2x = +c2-c1 ... (m1-m2)x = +c2-c1 ... x = (c2-c1)/(m1-m2)
	double x = (otherLine.c-self.c)/(self.m-otherLine.m);
	//NSLog(@"getIntersectionWith: x = %1.1f = (%1.1f-%1.1f)/(%1.1f-%1.1f)", x, otherLine.c, self.c, self.m, otherLine.m);
	return cv::Point(x, self.m*x+self.c);
}
-(double)getIntersectionBetweenXAxisAndParallelThrough:(cv::Point)p
{
	if (self.isVerticle)
	{
		return (double)p.x;
	}
	
	double c = (double)p.y-self.m*(double)p.x;
	// y=mx+c ... y-c=mx ... (y-c)/m=x
	return ((double)p.y-c)/self.m;
}

@end

@interface ACXAOMarkerDetails : ACXMarkerDetails
@property cv::Point centerPoint;
@property cv::Point regionCenterPoint;
@property ACXLine *xAxis, *yAxis, *xAxisOpposite, *yAxisOpposite;
-(ACXAOMarkerDetails*)initWithCenterPoint:(cv::Point)centerPoint andRegionPoint:(cv::Point)regionPoint andExistingDeatils:(ACXMarkerDetails*)details;
@end
@implementation ACXAOMarkerDetails
-(ACXAOMarkerDetails*)initWithCenterPoint:(cv::Point)centerPoint andRegionPoint:(cv::Point)regionPoint andExistingDeatils:(ACXMarkerDetails*)details
{
	self = [super initWithDetails:details];
	self.centerPoint = centerPoint;
	self.regionCenterPoint = regionPoint;
	return self;
}
@end


@implementation MarkerCodeAreaOrientationOrderExtensionFactory

-(NSString*)getCodeFor:(ACXMarkerDetails*)details
{
	NSMutableString *code = [[NSMutableString alloc] init];
	for (NSMutableDictionary *regionDetails in details.regions)
	{
		[code appendFormat:@"%@%@%@", [code length]==0?@"":@":", regionDetails[REGION_VALUE], regionDetails[REGION_LABEL]];
	}
	return code;
}

-(ACXMarkerDetails*)parseRegionsAt:(int)nodeIndex withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withExperience:(Experience*)experience error:(DetectionError*)error
{
	ACXMarkerDetails *details = [super parseRegionsAt:nodeIndex withContours:contours andHierarchy:hierarchy withExperience:experience error:error];
	
	if (details != nil)
	{
		NSMutableArray* regionsWithMaxDots = [[NSMutableArray alloc] init];
		int maxDots = -1;
		
		if (details.embeddedChecksum!=nil)
		{
			[regionsWithMaxDots addObject:@{REGION_INDEX:details.embeddedChecksumRegionIndex,REGION_VALUE:details.embeddedChecksum}];
			maxDots = 10000000;
		}
		
		// find/add areas
		for (NSMutableDictionary *regionDetails in details.regions)
		{
			// find area
			cv::vector<cv::Point> region = contours.at([regionDetails[REGION_INDEX] intValue]);
			double area = cv::contourArea(region);
			[regionDetails setObject:@(area) forKey:REGION_AREA];
			
			//max dots
			if ([regionDetails[REGION_VALUE] intValue] == 0)
			{
				[regionsWithMaxDots removeAllObjects];
				[regionsWithMaxDots addObject:regionDetails];
				maxDots = 10000000;
			}
			else if ([regionDetails[REGION_VALUE] intValue] == maxDots)
			{
				[regionsWithMaxDots addObject:regionDetails];
			}
			else if ([regionDetails[REGION_VALUE] intValue] > maxDots)
			{
				[regionsWithMaxDots removeAllObjects];
				[regionsWithMaxDots addObject:regionDetails];
				maxDots = [regionDetails[REGION_VALUE] intValue];
			}
		}
		
		// find orientation
		cv::Moments mo = cv::moments(contours.at(details.markerIndex));
		cv::Point centerOfMarker = cv::Point(mo.m10/mo.m00 , mo.m01/mo.m00);
		double cx=0, cy=0;
		for (NSDictionary* region in regionsWithMaxDots)
		{
			mo = cv::moments(contours.at([region[REGION_INDEX] intValue]));
			cx += mo.m10/mo.m00;
			cy += mo.m01/mo.m00;
		}
		cv::Point centerOfRegion = cv::Point(cx/[regionsWithMaxDots count], cy/[regionsWithMaxDots count]);
		ACXAOMarkerDetails *markerDetail = [[ACXAOMarkerDetails alloc] initWithCenterPoint:centerOfMarker andRegionPoint:centerOfRegion andExistingDeatils:details];
		details = markerDetail;
		ACXLine *lineOfGravity = [[ACXLine alloc] initWithStartPoint:centerOfMarker andEndPoint:centerOfRegion];
		
		cv::Rect boundingBox = cv::boundingRect(contours.at(details.markerIndex));
		[self defineAxisForBoundingBox:boundingBox andLineOfGravity:lineOfGravity inMarkerDetail:markerDetail];
		
		cv::Point origin = [markerDetail.xAxis getIntersectionWith:markerDetail.yAxis];
		for (NSMutableDictionary* regionDetail in markerDetail.regions)
		{
			cv::vector<cv::Point> regionContour = contours.at([regionDetail[REGION_INDEX] intValue]);
			double minX = 0;
			cv::Point minPoint, minIntersectionPoint;
			for (int i=0; i<regionContour.size(); ++i)
			{
				ACXLine *lineToXAxis = [[ACXLine alloc] initWithPoint:regionContour.at(i) andGradient:lineOfGravity.m];
				cv::Point intersectionPoint = [lineToXAxis getIntersectionWith:markerDetail.xAxis];
				double x = sqrt(pow((double)origin.x-(double)intersectionPoint.x, 2)+pow((double)origin.y-(double)intersectionPoint.y, 2));
				if (i==0 || x<minX)
				{
					minX = x;
					minPoint = regionContour.at(i);
					minIntersectionPoint = intersectionPoint;
				}
			}
			regionDetail[@"x"] = @(minX);
			regionDetail[@"sortPoint"] = @{@"x":@((double)minPoint.x), @"y":@((double)minPoint.y)};
			regionDetail[@"sortIntersectionPoint"] = @{@"x":@((double)minIntersectionPoint.x), @"y":@((double)minIntersectionPoint.y)};
		}
	}
	
	return details;
}

-(NSDictionary*)defineAxisForBoundingBox:(cv::Rect)bb andLineOfGravity:(ACXLine*)line inMarkerDetail:(ACXAOMarkerDetails*)markerDetail
{
	cv::Point tr = cv::Point(bb.br().x, bb.tl().y);
	cv::Point bl = cv::Point(bb.tl().x, bb.br().y);
	cv::Point tl = bb.tl();
	cv::Point br = bb.br();
	
	cv::Point xAxisPoint, yAxisPoint, xAxisPointOpp, yAxisPointOpp;
	cv::Point origin;
	
	NSString* debug;
	if (line.isVerticle)
	{
		if (line.pointsToXAxis)
		{
			debug = @"Verticle (1)";
			xAxisPoint = tl;
			yAxisPoint = br;
			xAxisPointOpp = yAxisPointOpp = bl;
			origin = tr;
		}
		else
		{
			debug = @"Verticle (2)";
			xAxisPoint = br;
			yAxisPoint = tl;
			xAxisPointOpp = yAxisPointOpp = tr;
			origin = bl;
		}
	}
	else if (line.isHorizontal)
	{
		if (line.pointsToYAxis)
		{
			debug = @"Horizontal (1)";
			xAxisPoint = bl;
			xAxisPointOpp = br;
			yAxisPoint = tr;
			yAxisPointOpp = br;
			origin = tl;
		}
		else
		{
			debug = @"Horizontal (2)";
			xAxisPoint = tr;
			xAxisPointOpp = tl;
			yAxisPoint = bl;
			yAxisPointOpp = tl;
			origin = br;
		}
	}
	else if (line.pointsToXAxis)
	{
		if (line.pointsToYAxis)
		{
			debug = @"(3)";
			yAxisPoint = tr;
			yAxisPointOpp = bl;
			xAxisPoint = tl;
			xAxisPointOpp = br;
		}
		else
		{
			debug = @"(4)";
			yAxisPoint = br;
			yAxisPointOpp = tl;
			xAxisPoint = tr;
			xAxisPointOpp = bl;
		}
	}
	else
	{
		if (line.pointsToYAxis)
		{
			debug = @"(5)";
			xAxisPoint = bl;
			xAxisPointOpp = tr;
			yAxisPoint = tl;
			yAxisPointOpp = br;
		}
		else
		{
			debug = @"(6)";
			xAxisPoint = br;
			xAxisPointOpp = tl;
			yAxisPoint = bl;
			yAxisPointOpp = tr;
		}
	}
	
	ACXLine *xAxis, *xAxisOpp, *yAxis, *yAxisOpp;
	cv::Point endOfXAxis, endOfYAxis;
	if (line.isVerticle || line.isHorizontal)
	{
		xAxis = [[ACXLine alloc] initWithStartPoint:origin andEndPoint:xAxisPoint];
		xAxisOpp = [[ACXLine alloc] initWithStartPoint:yAxisPoint andEndPoint:xAxisPointOpp];
		yAxis = [[ACXLine alloc] initWithStartPoint:origin andEndPoint:yAxisPoint];
		yAxisOpp = [[ACXLine alloc] initWithStartPoint:xAxisPoint andEndPoint:yAxisPointOpp];
		
		//endOfXAxis = xAxisPoint;
		//endOfYAxis = yAxisPoint;
	}
	else
	{
		xAxis = [[ACXLine alloc] initWithPoint:xAxisPoint andGradient:-1.0/line.m];
		xAxisOpp = [[ACXLine alloc] initWithPoint:xAxisPointOpp andGradient:-1.0/line.m];
		yAxis = [[ACXLine alloc] initWithPoint:yAxisPoint andGradient:line.m];
		yAxisOpp = [[ACXLine alloc] initWithPoint:yAxisPointOpp andGradient:line.m];
		
		//origin = [xAxis getIntersectionWith:yAxis];
		//endOfXAxis = [xAxis getIntersectionWith:yAxisOpp];
		//endOfYAxis = [yAxis getIntersectionWith:xAxisOpp];
	}
	
	if (markerDetail != nil)
	{
		markerDetail.xAxis = xAxis;
		markerDetail.yAxis = yAxis;
		markerDetail.xAxisOpposite = xAxisOpp;
		markerDetail.yAxisOpposite = yAxisOpp;
	}
	/*
	 NSLog(@"debug: %@", debug);
	 NSLog(@"XAXIS: y=%1.2fm+%1.2f (%1.2f)", xAxis.m, xAxis.c, xAxis.xAxisCrossPoint);
	 NSLog(@"YAXIS: y=%1.2fm+%1.2f (%1.2f)", yAxis.m, yAxis.c, yAxis.xAxisCrossPoint);
	 NSLog(@"XAXIS-O: y=%1.2fm+%1.2f (%1.2f)", xAxisOpp.m, xAxisOpp.c, xAxisOpp.xAxisCrossPoint);
	 NSLog(@"YAXIS-O: y=%1.2fm+%1.2f (%1.2f)", yAxisOpp.m, yAxisOpp.c, yAxisOpp.xAxisCrossPoint);
	 */
	return @{@"xAxis":xAxis,@"yAxis":yAxis,@"xAxisOpposite":xAxisOpp,@"yAxisOpposite":yAxisOpp};
}


-(void)sortCode:(ACXMarkerDetails*)details;
{
	// sort by area
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[REGION_AREA] doubleValue] < [b[REGION_AREA] doubleValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
	
	// label
	int count = 0;
	for (NSMutableDictionary *region in details.regions)
	{
		region[REGION_LABEL] = [NSString stringWithFormat:@"%c", (char)(65+count++)];
	}
	
	// sort by left to right
	[details.regions sortUsingComparator:^NSComparisonResult(id a, id b) {
		return [a[@"x"] doubleValue] < [b[@"x"] doubleValue] ? NSOrderedAscending : NSOrderedDescending;
	}];
}

-(void)drawMarker:(MarkerCode*)marker forImage:(cv::Mat&)image withContours:(cv::vector<cv::vector<cv::Point> >&)contours andHierarchy:(cv::vector<cv::Vec4i>&)hierarchy withMarkerColor:(cv::Scalar&)markerColor andOutlineColor:(cv::Scalar&)outlineColor andRegionColor:(cv::Scalar&)regionColor
{
	cv::Scalar colours[5];
	colours[0] = cv::Scalar(255*0, 255*0, 255*1, 255); // red
	colours[1] = cv::Scalar(255*0, 255*0.75, 255*1, 255); // orange
	colours[2] = cv::Scalar(255*0, 255*1, 255*0, 255); // green
	colours[3] = cv::Scalar(255*1, 255*0, 255*0, 255); // blue
	colours[4] = cv::Scalar(255*1, 255*0, 255*1, 255); // purple
	
	for (ACXAOMarkerDetails *markerDetails in marker.markerDetails)
	{
		NSNumber *nodeIndex = @(markerDetails.markerIndex);
		
		cv::drawContours(image, contours, [nodeIndex intValue], outlineColor, 3, 8, hierarchy, 0, cv::Point(0, 0));
		cv::drawContours(image, contours, [nodeIndex intValue], markerColor, 2, 8, hierarchy, 0, cv::Point(0, 0));
		cv::Point p = cv::boundingRect(contours.at([nodeIndex intValue])).tl();
		p.y+=18;
		
		int count = 0;
		for (NSDictionary *regionDetail in markerDetails.regions)
		{
			// draw region
			cv::drawContours(image, contours, [regionDetail[REGION_INDEX] intValue], colours[count%5], 1, 8, hierarchy, 0, cv::Point(0, 0));
			
			// draw minimum bounding rectangle
			cv::vector<cv::Point> region = contours.at([regionDetail[REGION_INDEX] intValue]);
			cv::RotatedRect minRect = cv::minAreaRect(region);
			
			cv::Point2f rectPoints[4];
			minRect.points(rectPoints);
			for(int j = 0; j < 4; j++)
			{
				cv::line(image, rectPoints[j], rectPoints[(j+1)%4], colours[count%5], 1, 8);
			}
			
			double areaAsPercentageOfSmallestRegionsArea = [regionDetail[REGION_AREA] doubleValue] / [markerDetails.regions[0][REGION_AREA] doubleValue];
			NSString *str = [[NSString alloc] initWithFormat:@"%1.2f", areaAsPercentageOfSmallestRegionsArea];
			cv::putText(image, str.fileSystemRepresentation, p, cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
			cv::putText(image, str.fileSystemRepresentation, p, cv::FONT_HERSHEY_SIMPLEX, 0.5, colours[count++%5], 2);
			p.x += 3 + 3 + ([str length]-1)*12;
		}
		
		// draw line of gravity
		//ACXAOMarkerDetails* markerDetail = self.markerDetails[nodeIndex];
		cv::line(image, markerDetails.centerPoint, markerDetails.regionCenterPoint, markerColor, 3);
		
		// draw (& label) the redefined x & y axis
		cv::Point origin = [markerDetails.xAxis getIntersectionWith:markerDetails.yAxis];
		cv::Point endOfXAxis = [markerDetails.xAxis getIntersectionWith:markerDetails.yAxisOpposite];
		cv::Point endOfYAxis = [markerDetails.yAxis getIntersectionWith:markerDetails.xAxisOpposite];
		
		cv::line(image, origin, endOfXAxis, markerColor, 3);
		cv::line(image, origin, endOfYAxis, markerColor, 3);
		
		cv::putText(image, @"x".fileSystemRepresentation, endOfXAxis, cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(image, @"x".fileSystemRepresentation, endOfXAxis, cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
		cv::putText(image, @"y".fileSystemRepresentation, endOfYAxis, cv::FONT_HERSHEY_SIMPLEX, 0.5, outlineColor, 3);
		cv::putText(image, @"y".fileSystemRepresentation, endOfYAxis, cv::FONT_HERSHEY_SIMPLEX, 0.5, markerColor, 2);
		
		// draw lines between x axis and the points on the region edge they were sorted by
		count = 0;
		for (NSDictionary *regionDetail in markerDetails.regions)
		{
			NSDictionary *temp = regionDetail[@"sortPoint"];
			cv::Point regionSortPoint([temp[@"x"] doubleValue],[temp[@"y"] doubleValue]);
			
			temp = regionDetail[@"sortIntersectionPoint"];
			cv::Point pointOnXAxis([temp[@"x"] doubleValue],[temp[@"y"] doubleValue]);
			
			cv::line(image, regionSortPoint, pointOnXAxis, colours[count++%5], 2);
		}
	}
}

@end
