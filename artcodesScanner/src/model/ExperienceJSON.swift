//
//  ExperienceJSON.swift
//  artcodes
//
//  Created by Kevin Glover on 06/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import SwiftyJSON

extension Experience
{
	public convenience init(json: JSON)
	{
		self.init(experienceID: json["id"].string!)
		name = json["name"].string
		description = json["description"].string
		author = json["author"].string
		icon = json["icon"].string
		image = json["image"].string
		
		if let items = json["markers"].array
		{
			for item in items
			{
				actions.append(Action(json: item))
			}
		}
	
		if let items = json["actions"].array
		{
			for item in items
			{
				actions.append(Action(json: item))
			}
		}
	}
	
	public func toJSON() -> JSON
	{
		return ""
	}
}

extension Action
{
    public convenience init(json: JSON)
    {
        self.init()
        
    }
}