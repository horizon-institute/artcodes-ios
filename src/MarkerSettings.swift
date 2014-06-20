//
//  ACSettings.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation

class ACMarkerSettings: NSObject
{
	var markers: Dictionary<String, ACMarker> = [:]
	var minRegions: Int = 5
	var maxRegions: Int = 5
	var maxEmptyRegions: Int = 0
	var maxRegionValue: Int = 6
	var minValidationRegions: Int = 2
	var validationRegionValue: Int = 1
	var checksumModulo: Int = 6

	init()
	{
		
	}
	
	init(file: String)
	{
		var error: NSError? = nil;
		let filePath = NSBundle.mainBundle().pathForResource("settings", ofType: "json");
		let data = NSData(contentsOfFile: filePath);
		//let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: error);
		
		if (!error)
		{
//			NSLog("Count %lu", json.count);
//			
//			for (key,value) in json
//			{
//				if(respondsToSelector(key))
//				{
//					setValue(value, key)
//				}
//			}
		}
	}
	
	/* 
	 * This function checks if the code fulfils the marker constraints provided in the settings.
	 * @return true if marker fulfils the constraint otherwise false.
	 */
	func isValid(marker: ACMarker) -> Bool
	{
		return hasValidNumberOfRegions(marker)
			&& hasValidNumberOfEmptyRegions(marker)
			&& hasValidNumberOfLeaves(marker)
			&& hasValidationRegions(marker)
			&& hasValidCheckSum(marker);
	}
	
	/*
	It checks the number of validation branches as set in the settings. The code is valid if the number of branches which contains the validation code are equal or greater than the number of validation branches mentioned in the settings.
 Returns true if the number of validation branches are >= validation branch value in the preference otherwise it returns false.
	*/
	func hasValidationRegions(marker: ACMarker) -> Bool
	{
		if(minValidationRegions == 0)
		{
			return true;
		}
		var numberOfValidationBranches = 0;
		//determine number of validation branches in the code.
		for leaf in marker.code
		{
			if (leaf == validationRegionValue)
			{
				numberOfValidationBranches++;
			}
		}
		return numberOfValidationBranches >= minValidationRegions;
	}
	
	/*
	This function divides the total number of leaves in the marker by the value given in the checksum preference. Code is valid if the modulo is 0.
	@return true if the number of leaves are divisible by the checksum value otherwise false.
	*/
	func hasValidCheckSum(marker: ACMarker) -> Bool
	{
		if(checksumModulo == 0)
		{
			return true;
		}
		var total = 0;
		for leaf in marker.code
		{
			total += leaf;
		}
		let checksum = total % checksumModulo;
		return checksum == 0;
	}
	
	func hasValidNumberOfRegions(marker: ACMarker) -> Bool
	{
		return (marker.code.count >= minRegions) && (marker.code.count <= maxRegions);
	}
	
	func hasValidNumberOfEmptyRegions(marker: ACMarker) -> Bool
	{
		return marker.emptyRegionCount <= maxEmptyRegions;
	}
	
	func hasValidNumberOfLeaves(marker: ACMarker) -> Bool
	{
		for leaf in marker.code
		{
			if leaf > maxRegionValue
			{
				return false
			}
		}
		
		return true;
	}
}
