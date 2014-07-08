//
//  TemporalMarkers.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
import Foundation

class MarkerDetector
{
	var occurences: Dictionary<String, (Marker, Int)> = [:]
	var startTime: NSDate = NSDate()
	var endTime: NSDate = NSDate()
	
	let duration: NSTimeInterval = 1;

	
	func integrateMarkers(markers: NSDictionary)
	{
		//if there are markers in the list.
		if (markers.count == 0)
		{
			return
		}

		//check if this is the first marker detected in particular duration.
		if (occurences.count == 0)
		{
			//initialize time
			startTime = NSDate()
			endTime = startTime.dateByAddingTimeInterval(duration)
		}
	
		//check if marker is within start & end time.
		let now = NSDate()
		if (isTimeInCurrentInterval(now))
		{
			for (codeObj : AnyObject, markerObj : AnyObject) in markers
			{
				let code = codeObj as String
				let marker = markerObj as Marker
				let occurence = marker.nodeIndices.count
				//increase occurence if this marker is already in the list.
				let existing = occurences[marker.codeKey]
				if existing
				{
					let (existingMarker, count) = existing!
					occurences[marker.codeKey] = (marker, occurence + count)
				}
				else
				{
					occurences[marker.codeKey] = (marker, occurence);
				}
			}
		}
	}
	
	func isMarkerDetectionTimeUp() -> Bool
	{
		let now = NSDate()
		return (now.compare(endTime) == NSComparisonResult.OrderedSame || (now.compare(endTime) == NSComparisonResult.OrderedDescending))
	}
	
	func isTimeInCurrentInterval(markerTime: NSDate) -> Bool
	{
		//if input marker is with in start & end time.
		return ((markerTime.compare(startTime) == NSComparisonResult.OrderedSame || (markerTime.compare(startTime) == NSComparisonResult.OrderedDescending)) &&
			((markerTime.compare(endTime) == NSComparisonResult.OrderedSame) || (markerTime.compare(endTime) == NSComparisonResult.OrderedAscending)))
	}
	
	var guessMarker: Marker?
	{
		var marker: Marker?
		var maxOccurence = 0;
		for (tempMarker, count) in occurences.values
		{
			if count > maxOccurence
			{
				maxOccurence = count;
				marker = tempMarker;
			}
		}
		return marker
	}
	
	func reset()
	{
		occurences.removeAll()
	}
	
	var integration: Float
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
			let timePassed: Double = now.timeIntervalSinceDate(startTime)
			let totalTime: Double = endTime.timeIntervalSinceDate(startTime)

			return Float(timePassed / totalTime)
		}
		return 0;
	}
	
	func hasIntegrationStarted() -> Bool
	{
		return occurences.count == 0;
	}
}