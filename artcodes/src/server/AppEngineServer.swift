//
//  AppEngineServer.swift
//  artcodes
//
//  Created by Kevin Glover on 11/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner
import Alamofire
import SwiftyJSON

class AppEngineServer: ArtcodeServer
{
    var accounts: [Account] = [LocalAccount()]
    
	func loadRecommended(closure: ([String : [String]]) -> Void)
	{
		// TODO
		Alamofire.request(.GET, "https://aestheticodes.appspot.com/recommended").response { (request, response, data, error) -> Void in
			if let jsonData = data
			{
				let json = JSON(data: jsonData)
				var result : [String: [String]] = [:]
				for (key, value) in json
				{
					if let array = value.array
					{
						var items: [String] = []
						for item in array
						{
							items.append(item.string!)
						}
						
						if items.count > 0
						{
							result[key] = items
						}
					}
				}
				
				closure(result)
			}
		}
	}
	
	func loadExperience(uri: String, closure: (Experience) -> Void)
	{
        var url = uri
        if uri.hasPrefix("http://aestheticodes.appspot.com")
        {
            url = url.stringByReplacingOccurrencesOfString("http://aestheticodes.appspot.com", withString: "https://aestheticodes.appspot.com")
        }
		Alamofire.request(.GET, url).response { (request, response, data, error) -> Void in
			if let jsonData = data
			{
				let json = JSON(data: jsonData)
				closure(Experience(json: json))
			}
		}
	}
}