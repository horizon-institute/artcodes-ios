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
import ArtcodesScanner
import Alamofire
import SwiftyJSON

class AppEngineServer: ArtcodeServer
{
	var accounts: [String: Account] = ["local": LocalAccount()]
	var starred : [String] {
		get {
			var returnValue : [String]? = NSUserDefaults.standardUserDefaults().objectForKey("starred") as? [String]
			if returnValue == nil
			{
				returnValue = []
			}
			return returnValue!
		}
		set (newValue) {
			//  Each item in newValue is now a NSString
			let val = newValue as [NSString]
			NSUserDefaults.standardUserDefaults().setObject(val, forKey: "starred")
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	func loadRecommended(near: CLLocationCoordinate2D?, closure: ([String : [String]]) -> Void)
	{
		var url = "https://aestheticodes.appspot.com/recommended"
		if let location = near
		{
			url = url + "?lat=\(location.latitude)&lon=\(location.longitude)"
		}
		
		NSLog(url)
		
		Alamofire.request(.GET, url).response { (request, response, data, error) -> Void in
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
		
		var headers: [String:String] = [:]
		for (id, account) in accounts
		{
			if id.hasPrefix("google:")
			{
				if let appAccount = account as? AppEngineAccount
				{
					headers["Authorization"] = "Bearer \(appAccount.token)"
				}
			}
		}
		
		Alamofire.request(.GET, url, headers: headers).response { (request, response, data, error) -> Void in
			if let jsonData = data
			{
				let json = JSON(data: jsonData)
				closure(Experience(json: json))
			}
		}
	}
	
	func accountFor(experience: Experience) -> Account
	{
		let accountNames = accounts.keys.sort()
		for accountName in accountNames
		{
			if let account = accounts[accountName]
			{
				if account.canEdit(experience)
				{
					return account
				}
			}
		}
		if let accountName = accountNames.first
		{
			if let account = accounts[accountName]
			{
				return account
			}
		}

		return LocalAccount()
	}
}