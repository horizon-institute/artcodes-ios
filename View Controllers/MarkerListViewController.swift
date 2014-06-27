//
//  MarkerListController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//
import Foundation
import UIKit

class MarkerListViewController : UITableViewController, UITextFieldDelegate
{
	@IBOutlet var table: UITableView
	
	override func numberOfSectionsInTableView(UITableView) -> Int
	{
		return 3
	}

	override func shouldAutorotate() -> Bool
	{
		return false
	}
	
	override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
	{
		if(section == 0)
		{
			if markerSettings.addMarkers
			{
				return getMarkerCodes().count + 1
			}
			else
			{
				return getMarkerCodes().count
			}
		}
		else
		{
			return 1
		}
	}
	
	override func viewDidDisappear(animated: Bool)
	{
		saveSettings()
	}
	
	func saveSettings()
	{
		if markerSettings.changed
		{
			NSLog("Saving Settings")
			var dict = markerSettings.toDictionary()
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
			markerSettings.changed = false
		}
	}
	
	override func viewWillAppear(animated: Bool)
	{
		NSLog("Reload")
		table.reloadData()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject)
	{
		if (segue.identifier? == "MarkerSegue")
		{
			let vc = segue.destinationViewController as MarkerDetailEditController
			let tagIndex = table.indexPathForCell((sender as UITableViewCell))
			
			vc.marker = markerSettings.markers[getMarkerCodes()[tagIndex.row]]
		}
	}
	
	func getMarkerCodes() -> String[]
	{
		var markers: String[] = []
		for (code, marker) in markerSettings.markers
		{
			if marker.visible
			{
				markers += marker.code
			}
		}
		
		return sort(markers)
	}
	
	override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
	{
		let markerCodes = getMarkerCodes()
		if(indexPath.section == 0)
		{
			if(indexPath.row >= markerCodes.count)
			{
				return tableView.dequeueReusableCellWithIdentifier("AddMarkerPrototypeCell", forIndexPath: indexPath) as UITableViewCell
			}
			else
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("MarkerPrototypeCell", forIndexPath: indexPath) as UITableViewCell

				let code = markerCodes[indexPath.row]
				cell.textLabel.text = "Marker \(code)"
				cell.detailTextLabel.text = markerSettings.markers[code]?.action
	
				return cell;
			}
		}
		else if(indexPath.section == 1)
		{
			return tableView.dequeueReusableCellWithIdentifier("SettingsPrototypeCell", forIndexPath: indexPath) as UITableViewCell;
		}
		return tableView.dequeueReusableCellWithIdentifier("AboutPrototypeCell", forIndexPath: indexPath) as UITableViewCell;
	}
}