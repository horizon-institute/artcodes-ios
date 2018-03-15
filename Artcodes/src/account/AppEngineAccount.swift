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
	var urlsOfExperiencesThatHaveChangedHint: Set<URL> = Set()
	
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
	
	func loadLibrary(_ closure: @escaping ([String]) -> Void)
	{
		var request: URLRequest = URLRequest(url: URL(string: AppEngineAccount.library)!, cachePolicy: (self.numberOfExperiencesHasChangedHint ? .reloadRevalidatingCacheData : .useProtocolCachePolicy), timeoutInterval: 60)
		self.numberOfExperiencesHasChangedHint = false
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		
		Alamofire.request(request as URLRequestConvertible)
			.responseData { (response) -> Void in
				print("\(response.result):\(response.response.debugDescription)")
				do {
					if let jsonData = response.data
					{
						var result = try JSON(data: jsonData).arrayValue.map { $0.string!}
						
						// Store account experiences to array
						let val = result as [NSString]
						UserDefaults.standard.set(val, forKey: self.id)
						UserDefaults.standard.synchronize()
						
						// Load temp experiences (currently saving)
						let fileManager = FileManager.default
						if let dir = ArtcodeAppDelegate.getDirectory("temp")
						{
							do
							{
								let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
								for file in contents
								{
									let uri = AppEngineAccount.httpPrefix + "/" + file.lastPathComponent
									if !result.contains(uri)
									{
										result.append(uri)
									}
								}
							}
							catch
							{
								print("Error: \(error)")
							}
						}
						
						closure(result)
					}
				} catch {}
				
				if response.response?.statusCode == 401
				{
					GIDSignIn.sharedInstance().signInSilently()
					// TODO
				}
		}
	}
	
	func deleteExperience(_ experience: Experience)
	{
		if(canEdit(experience))
		{
			if let url = urlFor(experience.id)
			{
				self.numberOfExperiencesHasChangedHint = true
				Alamofire.request(url, method: .delete, headers: ["Authorization": "Bearer \(self.token)"])
					.response { (response) in
						//print("\(request):\(response)")
						if response.error != nil
						{
							print("Error: \(String(describing: response.error))")
						}
						else
						{
							var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
							if experienceList == nil
							{
								experienceList = []
							}
							if let experienceID = experience.id
							{
								experienceList!.removeObject(experienceID)
								let val = experienceList! as [NSString]
								UserDefaults.standard.set(val, forKey: self.id)
								UserDefaults.standard.synchronize()
							}
						}
				}
			}
		}
	}
	
	func urlFor(_ uri: String?) -> URL?
	{
		if let url = uri
		{
			if url.hasPrefix(AppEngineAccount.httpPrefix)
			{
				return URL(string: url.replacingOccurrences(of: AppEngineAccount.httpPrefix, with: AppEngineAccount.httpsPrefix))
			}
			else if url.hasPrefix(AppEngineAccount.httpsPrefix)
			{
				return URL(string: url)
			}
		}
		return nil
	}
	
	func saveTemp(_ experience: Experience)
	{
		if let fileURL = tempFileFor(experience)
		{
			if let text = experience.json.rawString(options:JSONSerialization.WritingOptions())
			{
				do
				{
					try text.write(to: fileURL, atomically: false, encoding: String.Encoding.utf8)
					//print("Saved temp \(fileURL):\(text)")
				}
				catch
				{
					//print("Error saving file at path: \(fileURL) with error: \(error): text: \(text)")
				}
			}
		}
	}
	
	func saveExperience(_ experience: Experience)
	{
		experience.author = self.username
		
		var method = HTTPMethod.post
		var url = AppEngineAccount.httpsPrefix
		if canEdit(experience)
		{
			if let experienceURL = urlFor(experience.id)
			{
				method = HTTPMethod.put
				url = experienceURL.absoluteString
				self.urlsOfExperiencesThatHaveChangedHint.insert(experienceURL)
			}
		}
		
		if method == HTTPMethod.post
		{
			if experience.id != nil
			{
				experience.originalID = experience.id
			}
			experience.id = "tmp" + UUID().uuidString
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
					let json = try experience.json.rawData(options:JSONSerialization.WritingOptions())
					Alamofire.upload(json, to: url, method: .post, headers: ["Authorization": "Bearer \(self.token)"])
						.responseData { (response) -> Void in
							print("\(response.result):\(String(describing: response.response))")
							do {
								if let jsonData = response.data
								{
									self.deleteTemp(experience)
									let json = try JSON(data: jsonData)
									
									var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
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
											UserDefaults.standard.set(val, forKey: self.id)
											UserDefaults.standard.synchronize()
										}
									}
									print("JSON \(json)")
									experience.json = json
								}
							} catch {}
					}
				}
				catch
				{
					print("Error saving file at path: \(url) with error: \(error)")
				}
			}
		}
	}
	
	func deleteTemp(_ experience: Experience)
	{
		if let fileURL = tempFileFor(experience)
		{
			do
			{
				try FileManager.default.removeItem(at: fileURL)
				print("Deleted temp file \(fileURL)")
			}
			catch
			{
				print("Error deleting file at path: \(fileURL) with error: \(error)")
			}
		}
	}
	
	func requestFor(_ uri: String) -> URLRequest?
	{
		if let url = urlFor(uri)
		{
			if let dir = ArtcodeAppDelegate.getDirectory("temp")
			{
				let tempFile = dir.appendingPathComponent(url.lastPathComponent)
				do
				{
					if try tempFile.checkResourceIsReachable()
					{
						return URLRequest(url: tempFile)
					}
				}
				catch
				{
					// Not found
				}
			}
			
			var request: URLRequest = URLRequest(url: url, cachePolicy: ((self.urlsOfExperiencesThatHaveChangedHint.remove(url) != nil) ? .reloadRevalidatingCacheData : .useProtocolCachePolicy), timeoutInterval: 60)
			request.allHTTPHeaderFields = ["Authorization": "Bearer \(self.token)"]
			return request
		}
		return nil
	}
	
	func uploadImage(_ imageData: Data, closure: @escaping (String?) -> Void)
	{
		let hash = sha256(imageData)
		let imageURL = "https://aestheticodes.appspot.com/image/" + hash
		
		Alamofire.request(imageURL, method: .head)
			.response { response in
				debugPrint(response)
				
				if response.response == nil || response.response!.statusCode == 404
				{
					let headers = ["Authorization": "Bearer \(self.token)"]
					Alamofire.upload(imageData, to: imageURL, method: .put, headers: headers)
						.response { response in
							if response.response?.statusCode == 200
							{
								closure(imageURL)
							}
							else
							{
								closure(nil)
							}
					}
				}
				else if response.response!.statusCode == 200
				{
					closure(imageURL)
				}
				else
				{
					closure(nil)
				}
		}
	}
	
	func tempFileFor(_ experience: Experience) -> URL?
	{
		if let dir = ArtcodeAppDelegate.getDirectory("temp")
		{
			if let experienceID = experience.id
			{
				if let experienceURL = URL(string: experienceID)
				{
					if experienceURL.lastPathComponent != ""
					{
						return dir.appendingPathComponent(experienceURL.lastPathComponent)
					}
				}
			}
		}
		return nil
	}
	
	func isSaving(_ experience: Experience) -> Bool
	{
		if let fileURL = tempFileFor(experience)
		{
			return FileManager.default.fileExists(atPath: fileURL.path)
		}
		return false
	}
	
	func canEdit(_ experience: Experience) -> Bool
	{
		if let id = experience.id
		{
			var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
			if experienceList == nil
			{
				experienceList = []
			}
			return experienceList!.contains(id)
		}
		return false
	}
	
	func getAsset(_ source: String?) -> PHAsset?
	{
		if source != nil && source!.hasPrefix("assets-library://")
		{
			if let url = URL(string: source!)
			{
				let fetch = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
				
				if let asset = fetch.firstObject
				{
					return asset
				}
			}
		}
		return nil
	}
	
	func uploadImage(_ source: String?, closure: @escaping (String?) -> Void)
	{
		if let asset = getAsset(source)
		{
			let manager = PHImageManager.default()
			
			let options = PHImageRequestOptions()
			options.isSynchronous = false
			options.resizeMode = .exact
			options.deliveryMode = .highQualityFormat
			
			if asset.pixelWidth > imageMax || asset.pixelHeight > imageMax
			{
				print("Image too large (\(asset.pixelWidth) x \(asset.pixelHeight)). Using smaller image")
				let size = CGSize(width: imageMax, height: imageMax)
				manager.requestImage(for: asset,
				                     targetSize: size,
				                     contentMode: .aspectFit,
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
				manager.requestImageData(for: asset, options: options)
				{ (data, _, _, _) -> Void in
					if let imageData = data
					{
						self.uploadImage(imageData, closure: closure)
					}
					else
					{
						// Error?
						print("Image data not available?")
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
	
	func sha256(_ data : Data) -> String
	{
		var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		CC_SHA256((data as NSData).bytes, CC_LONG(data.count), &hash)
		var hashString = String()
		for byte in hash {
			hashString += String(format:"%02hhx", byte)
		}
		print("Hash = \(hashString)")
		return hashString
	}
}
