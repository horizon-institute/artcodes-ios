//
//  MarkerDetail.swift
//  aestheticodes
//
//  Created by Kevin Glover on 12/06/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

import Foundation

class MarkerDetail
{
	var code: String
	var action: String
	var editable = true
	var showDetail = true
	var description = "%s"
	var title = "Marker %s"
	var image: String?
	
	init(code: String, action: String)
	{
		self.code = code
		self.action = action
	}
	
	init(dict: NSDictionary)
	{
		self.code = dict["code"] as String
		self.action = dict["action"] as String
		dict["editable"]
	}
}