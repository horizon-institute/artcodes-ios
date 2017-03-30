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
	// Hints used to determine cache usage:
	var numberOfExperiencesHasChangedHint: Bool = false
	var urlsOfExperiencesThatHaveChangedHint: Set<NSURL> = Set()
	
	static let httpPrefix = "http://aestheticodes.appspot.com/experience"
	static let httpsPrefix = "https://aestheticodes.appspot.com/experience"
	static let library = "https://aestheticodes.appspot.com/experiences"
	static let interaction = "https://aestheticodes.appspot.com/interaction"
	
	let imageMax = 1024
    var email: String
    var token: String
    var name: String
    {
        return username
    }
	var username: String
	
	var location: String
	{
		return "as \(username)"
	}
	
    var id: String
    {
        return "google:\(email)"
    }
	
	var local: Bool
	{
		return false
	}
	
	init(email: String, name: String, token: String)
    {
        self.email = email
        self.token = token
		self.username = name
    }
	
    func loadLibrary(closure: ([String]) -> Void)
	{
		let request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: AppEngineAccount.library)!, cachePolicy: (self.numberOfExperiencesHasChangedHint ? .ReloadRevalidatingCacheData : .UseProtocolCachePolicy), timeoutInterval: 60)
		self.numberOfExperiencesHasChangedHint = false
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		
		Alamofire.request(request)
			.responseData { (response) -> Void in
				NSLog("%@: %@", "\(response.result)", "\(response.response)")
				if let jsonData = response.data
				{
					var result = JSON(data: jsonData).arrayValue.map { $0.string!}
				
					// Store account experiences to array
					let val = result as [NSString]
					NSUserDefaults.standardUserDefaults().setObject(val, forKey: self.id)
					NSUserDefaults.standardUserDefaults().synchronize()
		
					// Load temp experiences (currently saving)
					let fileManager = NSFileManager.defaultManager()
					if let dir = ArtcodeAppDelegate.getDirectory("temp")
					{
						do
						{
							let contents = try fileManager.contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
							for file in contents
							{
								if let id = file.lastPathComponent
								{
									let uri = AppEngineAccount.httpPrefix + "/" + id
									if !result.contains(uri)
									{
										result.append(uri)
									}
								}
							}
						}
						catch
						{
							NSLog("Error: %@", "\(error)")
						}
					}
				
					closure(result)
				}
			
				if response.response?.statusCode == 401
				{
					GIDSignIn.sharedInstance().signInSilently()
					// TODO
				}
        }
    }
	
	func deleteExperience(experience: Experience)
	{
		if(canEdit(experience))
		{
			if let url = urlFor(experience.id)
			{
				self.numberOfExperiencesHasChangedHint = true
				Alamofire.request(.DELETE, url, headers: ["Authorization": "Bearer \(self.token)"])
					.response { (request, response, data, error) -> Void in
						NSLog("%@: %@", "\(request)", "\(response)")
						if error != nil
						{
							NSLog("Error: %@", "\(error)")
						}
						else
						{
							var experienceList : [String]? = NSUserDefaults.standardUserDefaults().objectForKey(self.id) as? [String]
							if experienceList == nil
							{
								experienceList = []
							}
							if let experienceID = experience.id
							{
								experienceList!.removeObject(experienceID)
								let val = experienceList! as [NSString]
								NSUserDefaults.standardUserDefaults().setObject(val, forKey: self.id)
								NSUserDefaults.standardUserDefaults().synchronize()
							}
						}
				}
			}
		}
	}
	
	func urlFor(uri: String?) -> NSURL?
	{
		if let url = uri
		{
			if url.hasPrefix(AppEngineAccount.httpPrefix)
			{
				return NSURL(string: url.stringByReplacingOccurrencesOfString(AppEngineAccount.httpPrefix, withString: AppEngineAccount.httpsPrefix))
			}
			else if url.hasPrefix(AppEngineAccount.httpsPrefix)
			{
				return NSURL(string: url)
			}
		}
		return nil
	}
	
	func saveTemp(experience: Experience)
	{
		if let fileURL = tempFileFor(experience)
		{
			if let text = experience.json.rawString(options:NSJSONWritingOptions())
			{
				do
				{
					try text.writeToURL(fileURL, atomically: false, encoding: NSUTF8StringEncoding)
					NSLog("Saved temp %@: %@", fileURL, text)
				}
				catch
				{
					NSLog("Error saving file at path: %@ with error: %@: text: %@", fileURL, "\(error)", text)
				}
			}
		}
	}
	
	func saveExperience(experience: Experience)
	{
		experience.author = self.username

		var method = Method.POST
		var url = AppEngineAccount.httpsPrefix
		if canEdit(experience)
		{
			if let experienceURL = urlFor(experience.id)
			{
				method = Method.PUT
				url = experienceURL.absoluteString!
				self.urlsOfExperiencesThatHaveChangedHint.insert(experienceURL)
			}
		}

		if method == Method.POST
		{
			if experience.id != nil
			{
				experience.originalID = experience.id
			}
			experience.id = "tmp" + NSUUID().UUIDString
			self.numberOfExperiencesHasChangedHint = true
		}
		
		saveTemp(experience)
		uploadImage(experience.image) { (imageURL) in
			if imageURL != nil
			{
				if experience.image == experience.icon
				{
					experience.icon = imageURL
				}
				experience.image = imageURL
				self.saveTemp(experience)
			}
			
			self.uploadImage(experience.icon) { (imageURL) in
			
				if imageURL != nil
				{
					experience.icon = imageURL
					self.saveTemp(experience)
				}
				
				do
				{
					let json = try experience.json.rawData(options:NSJSONWritingOptions())
					Alamofire.upload(method, url, headers: ["Authorization": "Bearer \(self.token)"], data: json)
						.responseData { (response) -> Void in
							NSLog("%@: %@", "\(response.result)", "\(response.response)")
							if let jsonData = response.data
							{
								self.deleteTemp(experience)
								let json = JSON(data: jsonData)
								
								var experienceList : [String]? = NSUserDefaults.standardUserDefaults().objectForKey(self.id) as? [String]
								if experienceList == nil
								{
									experienceList = []
								}
								if let experienceID = json["id"].string
								{
									if !experienceList!.contains(experienceID)
									{
										experienceList!.append(experienceID)
										let val = experienceList! as [NSString]
										NSUserDefaults.standardUserDefaults().setObject(val, forKey: self.id)
										NSUserDefaults.standardUserDefaults().synchronize()
									}
								}
								NSLog("JSON %@:", "\(json)")
								experience.json = json
							}
					}
				}
				catch
				{
					NSLog("Error saving file at path: %@ with error: %@", url, "\(error)")
				}
			}
		}
	}
	
	func deleteTemp(experience: Experience)
	{
		if let fileURL = tempFileFor(experience)
		{
			do
			{
				try NSFileManager.defaultManager().removeItemAtURL(fileURL)
				NSLog("Deleted temp file %@", "\(fileURL)")
			}
			catch
			{
				NSLog("Error deleting file at path: %@ with error: %@", "\(fileURL)", "\(error)")
			}
		}
	}

	func requestFor(uri: String) -> NSURLRequest?
	{
		if let url = urlFor(uri)
		{
			if let dir = ArtcodeAppDelegate.getDirectory("temp")
			{
				if let id = url.lastPathComponent
				{
					let tempFile = dir.URLByAppendingPathComponent(id)
					let errorPointer:NSErrorPointer = nil
					if tempFile!.checkResourceIsReachableAndReturnError(errorPointer)
					{
						return NSURLRequest(URL: tempFile!)
					}
				}
			}
			
			let request: NSMutableURLRequest = NSMutableURLRequest(URL: url, cachePolicy: ((self.urlsOfExperiencesThatHaveChangedHint.remove(url) != nil) ? .ReloadRevalidatingCacheData : .UseProtocolCachePolicy), timeoutInterval: 60)
			request.allHTTPHeaderFields = ["Authorization": "Bearer \(self.token)"]
			return request
		}
		return nil
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
	
	func tempFileFor(experience: Experience) -> NSURL?
	{
		if let dir = ArtcodeAppDelegate.getDirectory("temp")
		{
			if let experienceID = experience.id
			{
				if let experienceURL = NSURL(string: experienceID)
				{
					if let id = experienceURL.lastPathComponent
					{
						return dir.URLByAppendingPathComponent(id)
					}
				}
			}
		}
		return nil
	}
	
	func isSaving(experience: Experience) -> Bool
	{
		if let fileURL = tempFileFor(experience)
		{
			if let path = fileURL.path
			{
				return NSFileManager.defaultManager().fileExistsAtPath(path)
			}
		}
		return false
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
				NSLog("Image too large (%@ x %@). Using smaller image", "\(asset.pixelWidth)", "\(asset.pixelHeight)")
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
		NSLog("Hash = %@", "\(hashString)")
		return hashString
	}
}
