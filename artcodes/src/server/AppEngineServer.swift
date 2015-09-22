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