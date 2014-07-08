//
//  ACSettings.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation

var markerSettings = MarkerSettings()

class MarkerSettings: NSObject
{
	var viewModes = ["detect", "outline", "threshold"]
	var markers: Dictionary<String, MarkerDetail> = [:]
	var minRegions: Int = 5
	var maxRegions: Int = 5
	var maxEmptyRegions: Int = 0
	var maxRegionValue: Int = 6
	var validationRegions: Int = 2
	var validationRegionValue: Int = 1
	var checksumModulo: Int = 0
	var editable = true
	var addMarkers = true
	var changed = false
	var updateURL = "http://www.wornchaos.org/settings.json";
	
	func toDictionary() -> NSDictionary
	{
		var propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
			
		var markerArray = NSMutableArray()
		for marker in markers.values
		{
			markerArray.addObject(marker.toDictionary())
		}
		propertiesDictionary.setValue(markerArray, forKey: "markers")
		
		var viewModes: NSArray = self.viewModes as NSArray
		propertiesDictionary.setValue(viewModes, forKey: "viewModes")
		propertiesDictionary.setValue(minRegions, forKey: "minRegions")
		propertiesDictionary.setValue(maxRegions, forKey: "maxRegions")
		propertiesDictionary.setValue(maxEmptyRegions, forKey: "maxEmptyRegions")
		propertiesDictionary.setValue(maxRegionValue, forKey: "maxRegionValue")

		propertiesDictionary.setValue(validationRegions, forKey: "validationRegions")
		propertiesDictionary.setValue(validationRegionValue, forKey: "validationRegionValue")
		propertiesDictionary.setValue(checksumModulo, forKey: "checksumModulo")
		propertiesDictionary.setValue(editable, forKey: "editable")
		
		return propertiesDictionary
	}
	
	func setIntValue(value: Int?, key: String)
	{
		NSLog("Attempting to set \(key) to \(value)")
		if !value
		{
			NSLog("Value == nil. Return")
			return
		}
		if respondsToSelector(Selector(key))
		{
			if valueForKey(key) is Int
			{
				let current = valueForKey(key) as Int
				if current != value
				{
					setValue(value, forKey: key)
					changed = true
				}
				else
				{
					NSLog("Value the same")
				}
			}
			else
			{
				NSLog("Existing value not int")
			}
		}
		else
		{
			NSLog("No property named \(key)")
		}
	}
	
	func load(json: JSONValue)
	{
		if json.object
		{
			NSLog("Loading json")
			for (key, value) in json.object!
			{
				if key == "markers"
				{
					if value.array
					{
						markers.removeAll(keepCapacity: true)
						for marker in value.array!
						{
							let markerDetail = MarkerDetail(json: marker)
							markers[markerDetail.code] = markerDetail
						}
					}
				}
				else if respondsToSelector(Selector(key))
				{
					NSLog("Adding \(key)")
					switch value
					{
						case .JString(let stringValue):
							setValue(stringValue, forKey: key)
						case .JNumber(let numberValue):
							setValue(numberValue, forKey: key)
						case .JBool(let boolValue):
							setValue(boolValue, forKey: key)
						//case .JArray(let arrayValue):
						//	setValue(arrayValue, forKey: key)
						default:
							NSLog("Don't know what to do with \(key)")
					}
				}
			}
			markerSettings.changed = false
		}
		else
		{
			NSLog("Invalid JSON")
		}
	}
	
	/*
	 * This function checks if the code fulfils the marker constraints provided in the settings.
	 * @return true if marker fulfils the constraint otherwise false.
	 */
	func isValid(code marker: Int[]) -> Bool
	{
		return hasValidNumberOfRegions(marker)
			&& hasValidNumberOfEmptyRegions(marker)
			&& hasValidNumberOfLeaves(marker)
			&& hasValidationRegions(marker)
			&& hasValidCheckSum(marker);
	}
	
	func isValid(string marker: String) -> Bool
	{
		let codes = marker.componentsSeparatedByString(":")
		var intCodes: Int[] = [];
		for code in codes
		{
			var value = code.toInt()
			if(value)
			{
				intCodes += value!
			}
			else
			{
				return false;
			}
		}
		return isValid(code: intCodes)
	}
	
	func isValid(marker: Marker) -> Bool
	{
		return isValid(code: marker.code)
	}
	
	/*
	 * It checks the number of validation branches as set in the settings. The code is valid if the number of branches which contains the validation code are equal or greater than the number of validation branches mentioned in the settings.
 Returns true if the number of validation branches are >= validation branch value in the preference otherwise it returns false.
	*/
	func hasValidationRegions(marker: Int[]) -> Bool
	{
		if(validationRegions == 0)
		{
			return true;
		}
		var numberOfValidationBranches = 0;
		//determine number of validation branches in the code.
		for value in marker
		{
			if (value == validationRegionValue)
			{
				numberOfValidationBranches++;
			}
		}
		return numberOfValidationBranches >= validationRegions;
	}
	
	/*
	 * This function divides the total number of leaves in the marker by the value given in the checksum preference. Code is valid if the modulo is 0.
	 * @return true if the number of leaves are divisible by the checksum value otherwise false.
	 */
	func hasValidCheckSum(marker: Int[]) -> Bool
	{
		if(checksumModulo == 0)
		{
			return true;
		}
		var total = 0;
		for value in marker
		{
			total += value;
		}
		let checksum = total % checksumModulo;
		return checksum == 0;
	}
	
	func hasValidNumberOfRegions(marker: Int[]) -> Bool
	{
		return (marker.count >= minRegions) && (marker.count <= maxRegions);
	}
	
	func hasValidNumberOfEmptyRegions(marker: Int[]) -> Bool
	{
		var emptyRegions = 0;
		
		for value in marker
		{
			if (value == 0)
			{
				emptyRegions++;
			}
		}
		return emptyRegions <= maxEmptyRegions;
	}

	func hasValidNumberOfLeaves(marker: Int[]) -> Bool
	{
		for value in marker
		{
			if value > maxRegionValue
			{
				return false
			}
		}
		
		return true;
	}
}
