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
			var returnValue : [String]? = UserDefaults.standard.object(forKey: "starred") as? [String]
			if returnValue == nil
			{
				returnValue = []
			}
			return returnValue!
		}
		set (newValue) {
			let val = newValue as [NSString]
			UserDefaults.standard.set(val, forKey: "starred")
			UserDefaults.standard.synchronize()
		}
	}
	var recent: [String] {
		get {
			var returnValue : [String]? = UserDefaults.standard.object(forKey: "recent") as? [String]
			if returnValue == nil
			{
				returnValue = []
			}
			return returnValue!
		}
		set (newValue) {
			//  Each item in newValue is now a NSString
			let val = newValue as [NSString]
			UserDefaults.standard.set(val, forKey: "recent")
			UserDefaults.standard.synchronize()
		}
	}
	
	func loadRecommended(_ near: CLLocationCoordinate2D?, closure: @escaping ([String : [String]]) -> Void)
	{
		var url = AppEngineServer.recommendedRoot
		if let location = near
		{
			url = url + "?lat=\(location.latitude)&lon=\(location.longitude)"
		}
		
		//NSLog("load URL: %@", url)
		
		Alamofire.request(url, method: .get)
			.responseData { (response) -> Void in
				//NSLog("response.result: %@, response.response: %@", "\(response.result)", "\(response.response)")
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
	
	func deleteExperience(_ experience: Experience)
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
	
	func loadExperience(_ uri: String, success: @escaping (Experience) -> Void, failure: @escaping (Error) -> Void)
	{
		var request: URLRequest?
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
			if let url = URL(string: uri)
			{
				request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
			}
		}
		
		if let finalRequest = request
		{
			Alamofire.request(finalRequest)
				.responseData { (response) -> Void in
					//NSLog("response.result: %@, response.request?.URL: %@, response.response: %@", "\(response.result)", "\(response.request?.URL)", "\(response.response)")
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
	
	func search(_ searchString: String, closure: @escaping ([String]) -> Void)
	{
		if let escapedString = searchString.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
		{
			let uri = "https://aestheticodes.appspot.com/search?q=\(escapedString)"
			//NSLog("Search URI: %@",uri)
			var request: URLRequest?
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
				if let url = URL(string: uri)
				{
					request = URLRequest(url: url)
				}
			}
			
			if let finalRequest = request
			{
				Alamofire.request(finalRequest)
					.responseData { (response) -> Void in
						//NSLog("response.result: %@, response.response: %@","\(response.result)", "\(response.response)")
						if let jsonData = response.data
						{
							//let string = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
							//NSLog("Encoded response: %@", "\(string)")
							let result = JSON(data: jsonData).arrayValue.map { $0.string!}
							
							closure(result)
						}
				}
			}
		}
	}
	
	func isSaving(_ experience: Experience) -> Bool
	{
		let accountNames = accounts.keys.sorted()
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
	
	func canEdit(_ experience: Experience) -> Bool
	{
		let accountNames = accounts.keys.sorted()
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
	
	func logInteraction(_ experience: Experience)
	{
		if let experienceID = experience.id
		{
			if experienceID.hasPrefix("http:") || experienceID.hasPrefix("https:")
			{
				if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
				{
					if let dict = NSDictionary(contentsOfFile: path)
					{
						if let clientID = dict["CLIENT_ID"] as? String
						{
							//NSLog("Log interaction %@", "\(experienceID)")
							_ = Alamofire.request(AppEngineAccount.interaction, method: .post, parameters: ["experience":experienceID], encoding: URLEncoding.httpBody, headers: ["Authorization": clientID])
						}
					}
				}

			}
		}
	}
	
	func accountFor(_ experience: Experience) -> Account
	{
		let accountNames = accounts.keys.sorted()
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
