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

	func load()
	{
		let url = NSURL(string:"http://www.wornchaos.org/settings.json")
		let request = NSURLRequest(URL:url)
		let queue = NSOperationQueue()
		
		NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ response, data, error in
			var parseError: NSError?
			let json: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &parseError) as NSDictionary

			let str = NSString(data:data,encoding:NSUTF8StringEncoding)
			NSLog("%@", str)
			if(response is NSHTTPURLResponse)
			{
				NSLog("HTTP")
				let httpURLResponse = response as NSHTTPURLResponse
				let headers: NSDictionary = httpURLResponse.allHeaderFields as NSDictionary
				for (header : AnyObject, value : AnyObject) in headers
				{
					NSLog("Header : \(header) = \(value)")
				}
			}
			
			if (!parseError)
			{
				self.load(json)
			}
			else
			{
				NSLog("Error loading settings: \(parseError?.localizedDescription)")
			}
		})
	}
	
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
	
	func save()
	{
		NSLog("Saving")
		var dict = toDictionary()
		var error: NSError?
		
		let json = NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
		
		let url = NSURL(string:"http://www.wornchaos.org/settings.json")

		let formatter = NSDateFormatter()
		formatter.dateFormat = "EEE, dd MMM yyyy hh:mm:ss zzz"
		let date = formatter.stringFromDate(NSDate())!
		
		var headers = NSMutableDictionary()
		headers.setValue("application/json", forKey: "Content-Type")
		headers.setValue(date, forKey: "Last-Modified")
		
		let response = NSHTTPURLResponse(URL: url, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: headers)
		let cacheResponse = NSCachedURLResponse(response: response, data: json)

		let request = NSURLRequest(URL: url)
		
		NSURLCache.sharedURLCache().removeAllCachedResponses()
		NSURLCache.sharedURLCache().storeCachedResponse(cacheResponse, forRequest: request)
	}
	
	func load(dict: NSDictionary)
	{
		for (key : AnyObject,value: AnyObject) in dict
		{
			// TODO Error handling to go here
			if key is String
			{
				let keyString: String = key as String
				if keyString == "markers"
				{
					if value is NSArray
					{
						for marker : AnyObject in value as NSArray
						{
							let dict = marker as? NSDictionary
							if(dict)
							{
								let markerDetails = MarkerDetail(dict: dict!)
								markers[markerDetails.code] = markerDetails
							}
						}
					}
				}
				else if respondsToSelector(Selector(keyString))
				{
					NSLog("\(key) = \(value)")
					setValue(value, forKey: keyString)
				}
				else
				{
					NSLog("\(key) = \(value) - unknown variable")
				}
			}
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
