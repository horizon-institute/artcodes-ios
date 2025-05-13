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
import CoreLocation

class CardographerServer: ArtcodeServer
{
    var root : String {
        get {
            return "https://cardographer.cs.nott.ac.uk/artcodes/"
        }
    }
    
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
    
    func loadRecommended(near: CLLocationCoordinate2D?, closure: @escaping (Result<[String : [String]], Error>) -> Void)
    {
        var url = root + "recommended"
        if let location = near
        {
            url = url + "?lat=\(location.latitude)&lon=\(location.longitude)"
        }
        
        NSLog("Loading Recommended from \(url)")
        AF.request(url).responseDecodable(of: [String: [String]].self) { (response) -> Void in
            if case .success(let value) = response.result
            {
                closure(.success(value))
            } else if case .failure(let error) = response.result
            {
                closure(.failure(error))
            }
        }
    }
    
    func addAccount(name: String, email: String, token: String) -> Account {
        let account = CardographerAccount(server: self, name: name, email: email, token: token)
        accounts[account.id] = account
        return account
    }
    
    func url(for id: String?) -> URL?
    {
        if let id = id {
            var fullUri = id.replacingOccurrences(of: "http://aestheticodes.appspot.com/experience/info/", with: "").replacingOccurrences(of: "http://aestheticodes.appspot.com/experience/", with: "")
            
            if(!fullUri.hasPrefix("http://") && !fullUri.hasPrefix("https://")) {
                fullUri = root + fullUri
            }
            
            return URL(string: fullUri)
        }
        return nil
    }
    
    func deleteExperience(experience: Experience)
    {
        for (_, account) in accounts
        {
            if account.canEdit(experience: experience)
            {
                account.deleteExperience(experience: experience)
                if let index = recent.firstIndex(of: experience.id) {
                    recent.remove(at: index)
                }
                if let index = starred.firstIndex(of: experience.id) {
                    starred.remove(at: index)
                }
                return
            }
        }
    }
    
    func loadExperience(uri: String, closure: @escaping (Result<Experience, Error>) -> Void)
    {
        var request: URLRequest?
        for (_, account) in accounts
        {
            if let result = account.requestFor(uri: uri)
            {
                request = result
                break
            }
        }
        
        if request == nil
        {
            if let url = url(for: uri)
            {
                request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
            }
        }
        
        if let finalRequest = request
        {
            NSLog("Loading \(finalRequest.url?.absoluteString ?? "Invalid URL")")
            AF.request(finalRequest).responseDecodable(of: Experience.self) { (response) -> Void in
                if case .success(let value) = response.result
                {
                    NSLog("\(value)")
                    closure(.success(value))
                }
                else if case .failure(let error) = response.result
                {
                    NSLog("\(error)")
                    closure(.failure(error))
                }
            }
        }
    }
    
    func search(searchString: String, closure: @escaping ([String]) -> Void)
    {
        if let escapedString = searchString.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        {
            let uri = root + "search?q=\(escapedString)"
            //NSLog("Search URI: %@",uri)
            var request: URLRequest?
            for (_, account) in accounts
            {
                if let result = account.requestFor(uri: uri)
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
                AF.request(finalRequest).responseDecodable(of: [String].self) { (response) -> Void in
                    if case .success(let value) = response.result
                    {
                        closure(value)
                    }
                    else if case .failure(let error) = response.result
                    {
                        NSLog("\(error)")
                    }
                }
            }
        }
    }
    
    func isSaving(experience: Experience) -> Bool
    {
        let accountNames = accounts.keys.sorted()
        for accountName in accountNames
        {
            if let account = accounts[accountName]
            {
                if account.isSaving(experience: experience)
                {
                    return true
                }
            }
        }
        return false
    }
    
    func canEdit(experience: Experience) -> Bool
    {
        let accountNames = accounts.keys.sorted()
        for accountName in accountNames
        {
            if let account = accounts[accountName]
            {
                if account.canEdit(experience: experience)
                {
                    return true
                }
            }
        }
        
        return false
    }
    
    func logInteraction(experience: Experience)
    {
        if experience.id.hasPrefix("http:") || experience.id.hasPrefix("https:")
        {
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
            {
                if let dict = NSDictionary(contentsOfFile: path)
                {
                    if let clientID = dict["CLIENT_ID"] as? String
                    {
                        //NSLog("Log interaction %@", "\(experienceID)")
                        AF.request(root + "interaction", method: .post, parameters: ["experience":experience.id], headers: ["Authorization": clientID]).response {_ in }
                    }
                }
            }
        }
    }
    
    func accountFor(experience: Experience) -> Account
    {
        let accountNames = accounts.keys.sorted()
        for accountName in accountNames
        {
            if let account = accounts[accountName]
            {
                if account.canEdit(experience: experience)
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
