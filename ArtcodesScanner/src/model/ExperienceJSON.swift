/*
 * Artcodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import SwiftyJSON

extension Experience
{
	public convenience init(json: JSON)
	{
		self.init()
		self.json = json
	}

	public convenience init(experience: Experience)
	{
		self.init(json: experience.json)
	}
	
	public var json: JSON
	{
		get
		{
			var json: JSON = [:]
			json["id"].string = id
			json["name"].string = name
			json["description"].string = description
			json["author"].string = author
			json["icon"].string = icon
			json["image"].string = image
			json["checksumModulo"].int = checksumModulo
			json["embeddedChecksum"].bool = embeddedChecksum
			json["originalID"].string = originalID
		
			var actionList: [JSON] = []
			for action in actions
			{
				actionList.append(action.json)
			}
			json["actions"] = JSON(actionList)

			if !availabilities.isEmpty
			{
				var availList: [JSON] = []
				for availability in availabilities
				{
					availList.append(availability.json)
				}
				json["availabilities"] = JSON(availList)
			}
			
			if !pipeline.isEmpty
			{
				json["pipeline"].arrayObject = pipeline
			}
		
			return json
		}
		set
		{
			if let idString = newValue["id"].string
			{
				id = idString
			}
			name = newValue["name"].string
			description = newValue["description"].string
			author = newValue["author"].string
			icon = newValue["icon"].string
			image = newValue["image"].string
			
			actions.removeAll()
			if let items = newValue["markers"].array
			{
				for item in items
				{
					actions.append(Action(json: item))
				}
			}
			
			if let items = newValue["actions"].array
			{
				for item in items
				{
					actions.append(Action(json: item))
				}
			}
			
			availabilities.removeAll()
			if let items = newValue["availabilities"].array
			{
				for item in items
				{
					availabilities.append(Availability(json: item))
				}
			}
			
			if let checksum = newValue["checksumModulo"].int
			{
				checksumModulo = checksum
			}
			
			if let embedded = newValue["embeddedCheksum"].bool
			{
				embeddedChecksum = embedded
			}
			
			pipeline = newValue["pipeline"].arrayValue.map { $0.string!}
		}
		
	}
}

extension Action
{
    public convenience init(json: JSON)
    {
        self.init()

		name = json["name"].string
		if let title = json["title"].string
		{
			name = title
		}
		url = json["url"].string
		if let action = json["action"].string
		{
			url = action
		}
		codes = json["codes"].arrayValue.map { $0.string!}
		if let code = json["code"].string
		{
			codes.append(code)
		}
		image = json["image"].string
		description = json["description"].string
		showDetail = json["showDetail"].boolValue
    }
	
	public var json: JSON
	{
		var json: JSON = [:]
		json["name"].string = name
		json["description"].string = description
		json["url"].string = url
		json["image"].string = image
		json["codes"].arrayObject = codes
		json["showDetail"].bool = showDetail
		// TODO json["match"].string
		
		return json
	}
}

extension Availability
{
	public convenience init(json: JSON)
	{
		self.init()
		
		name = json["name"].string
		lat = json["lat"].double
		lon = json["lon"].double
		start = json["start"].int
		end = json["end"].int
		address = json["address"].string
	}
	
	public var json: JSON
	{
		var json: JSON = [:]
		json["name"].string = name
		json["lat"].double = lat
		json["lon"].double = lon
		json["start"].int = start
		json["end"].int = end
		json["address"].string = address
		return json
	}
}