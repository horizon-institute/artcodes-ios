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
			if let id = self.id
			{
				json["id"].string = id
			}
			if let name = self.name
			{
				json["name"].string = name
			}
			if let description = self.description
			{
				json["description"].string = description
			}
			if let author = self.author
			{
				json["author"].string = author
			}
			if let icon = self.icon
			{
				json["icon"].string = icon
			}
			if let image = self.image
			{
				json["image"].string = image
			}
			if let originalID = self.originalID
			{
				json["originalID"].string = originalID
			}
			
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
			id = newValue["id"].string
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
			
			pipeline = newValue["pipeline"].arrayValue.map { $0.string! }
			
			if pipeline.isEmpty
			{
				pipeline.append("tile")
				if newValue["embeddedCheksum"].bool == true
				{
					pipeline.append("detectEmbedded")
				}
				else
				{
					pipeline.append("detect")
				}
			}
			
			saving = false
			callback?()
		}
	}
}

extension Action
{
	public convenience init(json: JSON)
	{
		self.init()
		self.json = json
	}
	
	public var json: JSON
	{
		get
		{
			var json: JSON = [:]
			json["name"].string = name
			if let description = self.description
			{
				json["description"].string = description
			}
			json["url"].string = url
			if let image = self.image
			{
				json["image"].string = image
			}
			json["codes"].arrayObject = codes
			if showDetail
			{
				json["showDetail"].bool = showDetail
			}
			if match == Match.all
			{
				json["match"].string = "all"
			}
			else if match == Match.sequence
			{
				json["match"].string = "sequence"
			}
			
			return json
		}
		set
		{
			
			name = newValue["name"].string
			if let title = newValue["title"].string
			{
				name = title
			}
			url = newValue["url"].string
			if let action = newValue["action"].string
			{
				url = action
			}
			codes = newValue["codes"].arrayValue.map { $0.string!}
			if let code = newValue["code"].string
			{
				codes.append(code)
			}
			image = newValue["image"].string
			description = newValue["description"].string
			showDetail = newValue["showDetail"].boolValue
			
			if let matchValue = newValue["match"].string
			{
				if matchValue == "any"
				{
					match = Match.any
				}
				else if matchValue == "all"
				{
					match = Match.all
				}
				else if matchValue == "sequence"
				{
					match = Match.sequence
				}
			}
			else
			{
				match = Match.any
			}
		}
	}
}

extension Availability
{
	public convenience init(json: JSON)
	{
		self.init()
		self.json = json

	}
	
	public var json: JSON
	{
		get
		{
			var json: JSON = [:]
			if let name = self.name
			{
				json["name"].string = name
			}
			if let lat = self.lat
			{
				json["lat"].double = lat
			}
			if let lon = self.lon
			{
				json["lon"].double = lon
			}
			if let start = self.start
			{
				json["start"].int = start
			}
			if let end = self.end
			{
				json["end"].int = end
			}
			if let address = self.address
			{
				json["address"].string = address
			}
			return json
		}
		
		set
		{
			name = newValue["name"].string
			lat = newValue["lat"].double
			lon = newValue["lon"].double
			start = newValue["start"].int
			end = newValue["end"].int
			address = newValue["address"].string
		}
	}
}