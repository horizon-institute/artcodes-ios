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
import Alamofire
import SwiftyJSON
import ArtcodesScanner
import Photos

class AppEngineAccount: Account
{
	static let httpPrefix = "http://aestheticodes.appspot.com/experiences"
	static let httpsPrefix = "https://aestheticodes.appspot.com/experiences"
	
	let imageMax = 1024
    var email: String
    var token: String
    var name: String
    {
        return email
    }
    
    var id: String
    {
        return "google:\(email)"
    }
    
    init(email: String, token: String)
    {
        self.email = email
        self.token = token
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
        let headers = [
            "Authorization": "Bearer \(token)"
        ]
        
        // TODO
        Alamofire.request(.GET, AppEngineAccount.httpsPrefix, headers: headers).response { (request, response, data, error) -> Void in
            if let jsonData = data
            {
                let result = JSON(data: jsonData).arrayValue.map { $0.string!}
				
				// Store account experiences to array
				let val = result as [NSString]
				NSUserDefaults.standardUserDefaults().setObject(val, forKey: self.id)
				NSUserDefaults.standardUserDefaults().synchronize()
				
                closure(result)
            }
			
			if response?.statusCode == 401
			{
				GIDSignIn.sharedInstance().signInSilently()
				// TODO 
			}
        }
    }
	
	func saveExperience(experience: Experience)
	{
		uploadImage(experience.image) { (imageURL) in
			if imageURL != nil
			{
				if experience.image == experience.icon
				{
					experience.icon = imageURL
				}
				experience.image = imageURL
			}
			
			self.uploadImage(experience.icon) { (imageURL) in
			
				if imageURL != nil
				{
					experience.icon = imageURL
				}
				
				var method = Method.POST
				var url = AppEngineAccount.httpsPrefix
				if let id = experience.id
				{
					if id.hasPrefix(AppEngineAccount.httpPrefix)
					{
						url = id.stringByReplacingOccurrencesOfString(AppEngineAccount.httpPrefix, withString: AppEngineAccount.httpsPrefix)
						method = Method.PUT
					}
					else if id.hasPrefix(AppEngineAccount.httpsPrefix)
					{
						url = id
						method = Method.PUT
					}
				}
				
				if let json = experience.json.rawString()?.dataUsingEncoding(NSUTF8StringEncoding)
				{
					let headers = ["Authorization": "Bearer \(self.token)"]
					Alamofire.upload(method, url, headers: headers, data: json)
						.response { (request, response, data, error) -> Void in
							if let jsonData = data
							{
								experience.json = JSON(data: jsonData)
							}
					}
				}
			}
		}
	}

	func uploadImage(imageData: NSData, closure: (String?) -> Void)
	{
		let hash = sha256(imageData)
		let imageURL = "https://aestheticodes.appspot.com/image/" + hash
		
		Alamofire.request(.HEAD, imageURL)
			.response { request, response, data, error in
				print(response)
				print(error)
				
				if response == nil || response!.statusCode == 404
				{
					let headers = ["Authorization": "Bearer \(self.token)"]
					Alamofire.upload(.PUT, imageURL, headers: headers, data: imageData)
						.response { request, response, data, error in
							if response != nil && response!.statusCode == 200
							{
								closure(imageURL)
							}
							else
							{
								closure(nil)
							}
					}
				}
				else if response!.statusCode == 200
				{
					closure(imageURL)
				}
				else
				{
					closure(nil)
				}
		}
	}
		
	func canEdit(experience: Experience) -> Bool
	{
		if let id = experience.id
		{
			var experienceList : [String]? = NSUserDefaults.standardUserDefaults().objectForKey(self.id) as? [String]
			if experienceList == nil
			{
				experienceList = []
			}
			NSLog("\(experienceList)")
			return experienceList!.contains(id)
		}
		return false
	}
	
	func getAsset(source: String?) -> PHAsset?
	{
		if source != nil && source!.hasPrefix("assets-library://")
		{
			if let url = NSURL(string: source!)
			{
				let fetch = PHAsset.fetchAssetsWithALAssetURLs([url], options: nil)
				
				if let asset = fetch.firstObject as? PHAsset
				{
					return asset
				}
			}
		}
		return nil
	}
	
	func uploadImage(source: String?, closure: (String?) -> Void)
	{
		if let asset = getAsset(source)
		{
			let manager = PHImageManager.defaultManager()
					
			let options = PHImageRequestOptions()
			options.synchronous = false
			options.resizeMode = .Exact
			options.deliveryMode = .HighQualityFormat
			
			if asset.pixelWidth > imageMax || asset.pixelHeight > imageMax
			{
				NSLog("Image too large (\(asset.pixelWidth) x \(asset.pixelHeight)). Using smaller image")
				let size = CGSize(width: imageMax, height: imageMax)
				manager.requestImageForAsset(asset,
					targetSize: size,
					contentMode: .AspectFit,
					options: options) { (finalResult, _) in
						if let image = finalResult
						{
							if let imageData = UIImageJPEGRepresentation(image, 0.9)
							{
								self.uploadImage(imageData, closure: closure)
							}
						}
				}
			}
			else
			{
				manager.requestImageDataForAsset(asset, options: options)
				{ (data, _, _, _) -> Void in
					if let imageData = data
					{
						self.uploadImage(imageData, closure: closure)
					}
					else
					{
						// Error?
						NSLog("Image data not available?")
						closure(nil)
					}
				}
			}
		}
		else
		{
			closure(nil)
		}
	}

	func sha256(data : NSData) -> String
	{
		var hash = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
		CC_SHA256(data.bytes, CC_LONG(data.length), &hash)
		var hashString = String()
		for byte in hash {
			hashString += String(format:"%02hhx", byte)
		}
		NSLog("Hash = \(hashString)")
		return hashString
	}
}