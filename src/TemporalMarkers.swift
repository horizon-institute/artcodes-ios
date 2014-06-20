//
//  TemporalMarkers.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation

class TemporalMarkers
{
	//@interface MarkerTemporalOccurence : NSObject
	//@property ACMarker *dtouchMarker;
	//@property int occurence;
	//@end
	
	//@implementation MarkerTemporalOccurence
	//@synthesize dtouchMarker;
	//@synthesize occurence;
	//@end
	
	var occurences: Dictionary<String, (ACMarker, Int)> = [:]
	var startTime: NSDate = NSDate()
	var endTime: NSDate = NSDate()
	
	let duration: NSTimeInterval = 2;

	
	func integrateMarkers(markers: Dictionary<String, ACMarker>)
	{
		//if there are markers in the list.
		if (markers.count > 0)
		{
			//check if this is the first marker detected in particular duration.
			if (occurences.count == 0)
			{
				//initialize time
				setupTime();
			}
	
			//check if marker is within start & end time.
			let now = NSDate()
			if (isTimeInCurrentInterval(now))
			{
				for (code, marker) in markers
				{
//					let occurence = marker.nodes.count
					//increase occurence if this marker is already in the list.
//					MarkerTemporalOccurence *existingOccurence = [markerOccurences objectForKey:markerCode];
//					if (existingOccurence != nil)
//					{
//						existingOccurence.occurence = existingOccurence.occurence + occurence;
//					}
//					else
//					{
//						//new marker has been detected.
//						MarkerTemporalOccurence *newOccurence = [[MarkerTemporalOccurence alloc] init];
//						newOccurence.dtouchMarker = [markers objectForKey:markerCode];
//						newOccurence.occurence = occurence;
//						[markerOccurences setObject:newOccurence forKey:dtouchMarker.codeKey];
//					}
				}
			}
		}
	}
	
	func isMarkerDetectionTimeUp() -> Bool
	{
		let now = NSDate()
		return (now.compare(endTime) == NSComparisonResult.OrderedSame || (now.compare(endTime) == NSComparisonResult.OrderedDescending))
	}
	
	//initialize start and end duration of current detection interval.
	func setupTime()
	{
		startTime = NSDate()
		endTime = startTime.dateByAddingTimeInterval(duration)
	}
	
	func isTimeInCurrentInterval(markerTime: NSDate) -> Bool
	{
		//if input marker is with in start & end time.
		return ((markerTime.compare(startTime) == NSComparisonResult.OrderedSame || (markerTime.compare(startTime) == NSComparisonResult.OrderedDescending)) &&
			((markerTime.compare(endTime) == NSComparisonResult.OrderedSame) || (markerTime.compare(endTime) == NSComparisonResult.OrderedAscending)))
	}
	
	func guessMarker() -> ACMarker?
	{
		var marker: ACMarker?
		var maxOccurence = 0;
		for markerCode in occurences
		{
//			MarkerTemporalOccurence *temporalMarker = [markerOccurences objectForKey:markerCode];
//			if (temporalMarker.occurence > maxOccurence)
//			{
//				marker = temporalMarker.dtouchMarker
//				maxOccurence = temporalMarker.occurence
//			}
		}
		return marker
	}
	
	func resetTemporalMarker()
	{
		occurences.removeAll()
	}
	
	func getIntegrationPercent() -> Float
	{
		let now = NSDate()
	
		if (occurences.count == 0)
		{
			return 0;
		}
		else if (isMarkerDetectionTimeUp())
		{
			return 1.0;
		}
		else if (isTimeInCurrentInterval(now))
		{
			//difference start time and current time. The result would be negative as current time is greater so
			// make it positive by multiplying by -1.
//			NSTimeInterval timePassed = [timeNow timeIntervalSinceDate:startTime];
			//difference start time and end time.
//			NSTimeInterval totalTime = [endTime timeIntervalSinceDate:startTime];
			//percentage.
			return 0 //timePassed/totalTime;
		}
		return 0;
	}
	
	func hasIntegrationStarted() -> Bool
	{
		return occurences.count == 0;
	}
}