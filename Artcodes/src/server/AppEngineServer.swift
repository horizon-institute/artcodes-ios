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
	static let recommendedRoot = "https://aestheticodes.appspot.com/recommended"
	
	var accounts: [String: Account] = [:]
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
			let val = newValue as [NSString]
			NSUserDefaults.standardUserDefaults().setObject(val, forKey: "starred")
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	var recent: [String] {
		get {
			var returnValue : [String]? = NSUserDefaults.standardUserDefaults().objectForKey("recent") as? [String]
			if returnValue == nil
			{
				returnValue = []
			}
			return returnValue!
		}
		set (newValue) {
			//  Each item in newValue is now a NSString
			let val = newValue as [NSString]
			NSUserDefaults.standardUserDefaults().setObject(val, forKey: "recent")
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	func loadRecommended(near: CLLocationCoordinate2D?, closure: ([String : [String]]) -> Void)
	{
		var url = AppEngineServer.recommendedRoot
		if let location = near
		{
			url = url + "?lat=\(location.latitude)&lon=\(location.longitude)"
		}
		
		NSLog(url)
		
		Alamofire.request(.GET, url)
			.responseData { (response) -> Void in
				NSLog("\(response.result): \(response.response)")
				if response.result.isSuccess
				{
					if let jsonData = response.data
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
	}
	
	func deleteExperience(experience: Experience)
	{
		for (_, account) in accounts
		{
			if account.canEdit(experience)
			{
				account.deleteExperience(experience)
				if let experienceID = experience.id
				{
					recent.removeObject(experienceID)
					starred.removeObject(experienceID)
				}
				return
			}
		}
	}
	
	func loadExperience(uri: String, success: (Experience) -> Void, failure: (NSError) -> Void)
	{
		var request: NSURLRequest?
		for (_, account) in accounts
		{
			if let result = account.requestFor(uri)
			{
				request = result
				break
			}
		}
		
		if request == nil
		{
			if let url = NSURL(string: uri)
			{
				request = NSURLRequest(URL: url)
			}
		}
		
		if let finalRequest = request
		{
			Alamofire.request(finalRequest)
				.responseData { (response) -> Void in
					NSLog("\(response.result): \(response.request?.URL) \(response.response)")
					if response.result.isSuccess
					{
						if let jsonData = response.data
						{
							let json = JSON(data: jsonData)
							if json.null == nil
							{
								let experience = Experience(json: json)
								if experience.id == nil
								{
									experience.id = uri
								}
								success(experience)
							}
						}
						else if let error = response.result.error
						{
							failure(error)
						}
					}
			}
		}
	}
	
	func search(searchString: String, closure: ([String]) -> Void)
	{
		if let escapedString = searchString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
		{
			let uri = "https://aestheticodes.appspot.com/search?q=\(escapedString)"
			NSLog("\(uri)")
			var request: NSURLRequest?
			for (_, account) in accounts
			{
				if let result = account.requestFor(uri)
				{
					request = result
					break
				}
			}
			
			if request == nil
			{
				if let url = NSURL(string: uri)
				{
					request = NSURLRequest(URL: url)
				}
			}
			
			if let finalRequest = request
			{
				Alamofire.request(finalRequest)
					.responseData { (response) -> Void in
						NSLog("\(response.result): \(response.response)")
						if let jsonData = response.data
						{
							let string = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
							NSLog("\(string)")
							let result = JSON(data: jsonData).arrayValue.map { $0.string!}
							
							closure(result)
						}
				}
			}
		}
	}
	
	func isSaving(experience: Experience) -> Bool
	{
		let accountNames = accounts.keys.sort()
		for accountName in accountNames
		{
			if let account = accounts[accountName]
			{
				if account.isSaving(experience)
				{
					return true
				}
			}
		}
		return false
	}
	
	func canEdit(experience: Experience) -> Bool
	{
		let accountNames = accounts.keys.sort()
		for accountName in accountNames
		{
			if let account = accounts[accountName]
			{
				if account.canEdit(experience)
				{
					return true
				}
			}
		}
		
		return false
	}
	
	func logInteraction(experience: Experience)
	{
		let accountNames = accounts.keys.sort()
		for accountName in accountNames
		{
			if let account = accounts[accountName]
			{
				if account.logInteraction(experience)
				{
					return
				}
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