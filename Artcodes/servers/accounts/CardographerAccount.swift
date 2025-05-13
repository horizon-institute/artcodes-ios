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
import ArtcodesScanner
import Photos
import GoogleSignIn
import CommonCrypto

class CardographerAccount: Account
{
    // Hints used to determine cache usage:
    var numberOfExperiencesHasChangedHint: Bool = false
    var urlsOfExperiencesThatHaveChangedHint: Set<URL> = Set()
    
    let decoder: JSONDecoder = JSONDecoder()
    
    let imageMax = 1024
    let server: ArtcodeServer
    let email: String
    let token: String
    var name: String
    {
        return username
    }
    let username: String
    
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
    
    init(server: ArtcodeServer, name: String, email: String, token: String)
    {
        self.server = server
        self.email = email
        self.token = token
        self.username = name
    }
    
    func loadLibrary(closure: @escaping ([String]) -> Void)
    {
        var request: URLRequest = URLRequest(url: URL(string: server.root + "experiences")!, cachePolicy: (self.numberOfExperiencesHasChangedHint ? .reloadRevalidatingCacheData : .useProtocolCachePolicy), timeoutInterval: 60)
        self.numberOfExperiencesHasChangedHint = false
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        AF.request(request).responseDecodable(of: [String].self) { (response) in
            if case .success(var result) = response.result
            {
                // Store account experiences to array
                UserDefaults.standard.set(result, forKey: self.id)
                UserDefaults.standard.synchronize()
                
                // Load temp experiences (currently saving)
                let fileManager = FileManager.default
                if let dir = self.getDirectory(name: "temp")
                {
                    do
                    {
                        let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
                        for file in contents
                        {
                            let id = file.lastPathComponent
                            let uri = self.server.root + id
                            if !result.contains(uri)
                            {
                                result.append(uri)
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
            else if case .failure(let error) = response.result
            {
                NSLog("Error: \(error)")
                if error.responseCode == 401 {
                    GIDSignIn.sharedInstance.restorePreviousSignIn()
                }
            }
        }
    }
    
    func deleteExperience(experience: Experience)
    {
        if(canEdit(experience: experience))
        {
            if let url = server.url(for: experience.id)
            {
                self.numberOfExperiencesHasChangedHint = true
                AF.request(url, method: .post, headers: ["Authorization": "Bearer \(self.token)"])
                    .response { (response) in
                        NSLog("%@: %@", "\(response)")
                        if response.error != nil
                        {
                            NSLog("Error: %@", "\(response.error)")
                        }
                        else
                        {
                            var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
                            if experienceList == nil
                            {
                                experienceList = []
                            }
                            
                            if let index = experienceList?.firstIndex(of: experience.id) {
                                experienceList?.remove(at: index)
                            }
                            UserDefaults.standard.set(experienceList, forKey: self.id)
                            UserDefaults.standard.synchronize()
                        }
                    }
            }
        }
    }
    
    func saveTemp(experience: Experience)
    {
        if let fileURL = tempFileFor(id: experience.id)
        {
            if let text = experience.json
            {
                do
                {
                    try text.write(to: fileURL, atomically: false, encoding: .utf8)
                    NSLog("Saved temp \(fileURL): \(text)")
                }
                catch
                {
                    NSLog("Error saving file at path: \(fileURL) with error: \(error): text: \(text)")
                }
            }
        }
    }
    
    func saveExperience(_ experience: Experience, closure: @escaping (Result<Experience, Error>) -> Void)
    {
        var experience = experience
        experience.author = self.username
        
        var method = HTTPMethod.post
        var url = server.root + "experience"
        if canEdit(experience: experience)
        {
            if let experienceURL = server.url(for: experience.id)
            {
                method = HTTPMethod.put
                url = experienceURL.absoluteString
                self.urlsOfExperiencesThatHaveChangedHint.insert(experienceURL)
            }
        } else {
            return
        }
        
        if method == HTTPMethod.post
        {
            experience.id = "tmp" + NSUUID().uuidString
            self.numberOfExperiencesHasChangedHint = true
        }
        let originalId = experience.id
        
        saveTemp(experience: experience)
        
        if let form = createForm(experience: experience) {
            AF.upload(multipartFormData: form, to: url, method: method, headers: ["Authorization": "Bearer \(self.token)"])
                .responseDecodable(of: Experience.self) { response in
                    if case .success(let result) = response.result
                    {
                        self.deleteTemp(id: originalId)
                        var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
                        if experienceList == nil
                        {
                            experienceList = []
                        }
                        if !experienceList!.contains(result.id)
                        {
                            experienceList!.append(result.id)
                            let val = experienceList! as [NSString]
                            UserDefaults.standard.set(val, forKey: self.id)
                            UserDefaults.standard.synchronize()
                        }
                        
                        closure(.success(result))
                    }
                    else if case .failure(let error) = response.result
                    {
                        NSLog("Error: \(error)")
                        if error.responseCode == 401 {
                            GIDSignIn.sharedInstance.restorePreviousSignIn()
                        }
                        
                        closure(.failure(error))
                    }
                }
        }
    }
    
    func deleteTemp(id: String)
    {
        if let fileURL = tempFileFor(id: id)
        {
            do
            {
                try FileManager.default.removeItem(at: fileURL)
                NSLog("Deleted temp file %@", "\(fileURL)")
            }
            catch
            {
                NSLog("Error deleting file at path: %@ with error: %@", "\(fileURL)", "\(error)")
            }
        }
    }
    
    func requestFor(uri: String) -> URLRequest?
    {
        if let url = server.url(for: uri)
        {
            if let dir = getDirectory(name: "temp")
            {
                let id = url.lastPathComponent
                let tempFile = dir.appendingPathComponent(id)
                if (try? tempFile.checkResourceIsReachable()) == true
                {
                    return URLRequest(url: tempFile)
                }
            }
            
            var request = URLRequest(url: url, cachePolicy: ((self.urlsOfExperiencesThatHaveChangedHint.remove(url) != nil) ? .reloadRevalidatingCacheData : .useProtocolCachePolicy), timeoutInterval: 60)
            request.addValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            return request
        }
        return nil
    }
    
    func tempFileFor(id: String) -> URL?
    {
        if let dir = getDirectory(name: "temp")
        {
            return dir.appendingPathComponent(id)
        }
        return nil
    }
    
    func getDirectory(name: String) -> URL?
    {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentDirectory:URL = urls.first
        {
            let dir = documentDirectory.appendingPathComponent(name, isDirectory: true)
            do
            {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                NSLog("Error: %@", "\(error)")
            }
            return dir
        }
        else
        {
            NSLog("Couldn't get documents directory!")
        }
        
        return nil
    }
    
    func isSaving(experience: Experience) -> Bool
    {
        if let fileURL = tempFileFor(id: experience.id)
        {
            return FileManager.default.fileExists(atPath: fileURL.absoluteString)
        }
        return false
    }
    
    func canEdit(experience: Experience) -> Bool
    {
        var experienceList : [String]? = UserDefaults.standard.object(forKey: self.id) as? [String]
        if experienceList == nil
        {
            experienceList = []
        }
        return experienceList!.contains(experience.id)
    }
    
    func createForm(experience: Experience) -> MultipartFormData? {
        let form = MultipartFormData()
        do {
            if let json = experience.jsonData {
                form.append(json, withName: "experience")
                if(experience.image == experience.icon) {
                    if let image = experience.image {
                        if image.starts(with: "file:") {
                            if let url = URL(string: image) {
                                form.append(url, withName: "image+icon")
                                return form
                            }
                        }
                    }
                } else {
                    if let image = experience.image {
                        if image.starts(with: "file:") {
                            if let url = URL(string: image) {
                                form.append(url, withName: "image")
                            }
                        }
                    }
                    if let icon = experience.icon {
                        if icon.starts(with: "file:") {
                            if let url = URL(string: icon) {
                                form.append(url, withName: "icon")
                            }
                        }
                    }
                    return form
                }
            }
        } catch {
            NSLog("Error encoding experience: \(error)")
        }
        return nil
    }
    
    func sha256(data : Data) -> String
    {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        var hashString = String()
        for byte in hash {
            hashString += String(format:"%02hhx", byte)
        }
        NSLog("Hash = %@", "\(hashString)")
        return hashString
    }
}
