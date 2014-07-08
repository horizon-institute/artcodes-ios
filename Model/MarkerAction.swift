//
//  MarkerDetail.swift
//  aestheticodes
//
//  Created by Kevin Glover on 12/06/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

import Foundation

class MarkerAction
{
	var code: String
	var action: String?
	var editable = true
	var showDetail = true
	var description: String?
	var title = "Marker %@"
	var image: String?
	var visible = true
	
	init(code: String)
	{
		self.code = code
	}
	
	init(json: JSONValue)
	{
		code = json["code"].string!
		NSLog("Adding marker \(code)")
		action = json["action"].string
		if json["editable"].bool
		{
			editable = json["editable"].bool!
		}

		NSLog("\(action)")
		
		if json["title"].string
		{
			title = json["title"].string!
		}
		
		if json["showDetail"].bool
		{
			showDetail = json["showDetail"].bool!
		}
		
		if json["visible"].bool
		{
			visible = json["visible"].bool!
		}
		
		description = json["description"].string
		image = json["image"].string
	}
	
	init(dict: NSDictionary)
	{
		code = dict["code"] as String
		action = dict["action"] as? String
		if dict["editable"]
		{
			editable = dict["editable"] as Bool
		}
		
		if dict["title"]
		{
			title = dict["title"] as String
		}
		
		if dict["showDetail"]
		{
			showDetail = dict["showDetail"] as Bool
		}

		if dict["visible"]
		{
			visible = dict["visible"] as Bool
		}
		
		description = dict["description"] as? String
		image = dict["image"] as? String
	}
	
	func toDictionary() -> NSDictionary
	{
		var propertiesDictionary : NSMutableDictionary = NSMutableDictionary()
		propertiesDictionary.setValue(code, forKey: "code")
		propertiesDictionary.setValue(action, forKey: "action")
		propertiesDictionary.setValue(editable, forKey: "editable")
		propertiesDictionary.setValue(title, forKey: "title")
		propertiesDictionary.setValue(showDetail, forKey: "showDetail")
		propertiesDictionary.setValue(description, forKey: "description")
		propertiesDictionary.setValue(image, forKey: "image")
		propertiesDictionary.setValue(visible, forKey: "visible")
		return propertiesDictionary
	}
}