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

class LocalAccount: Account
{
    func urlFor(_ uri: String?) -> URL?
    {
        if let uri = uri
        {
            if uri.hasPrefix("device:")
            {
                if let dir = getDirectory(name: "experiences")
                {
                    return dir.appendingPathComponent(String(uri[uri.index(uri.startIndex, offsetBy: 7)...]))
                }
            }
        }
        return nil
    }
    
    var id: String
    {
        return "local"
    }
    
    var location: String
    {
        return "to Device"
    }
    
    var name: String
    {
        return "Device"
    }
    
    var local: Bool
    {
        return true
    }
    
    func deleteExperience(experience: Experience)
    {
        if let fileURL = urlFor(experience.id)
        {
            let fileManager = FileManager.default
            do
            {
                try fileManager.removeItem(at: fileURL)
            }
            catch
            {
                NSLog("Error deleting %@, file: %@: %@", "\(experience.id)", "\(fileURL)", "\(error)")
            }
        }
    }
    
    func requestFor(uri: String) -> URLRequest?
    {
        if let url = urlFor(uri)
        {
            return URLRequest(url: url)
        }
        return nil
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
        let fileManager = FileManager.default
        do
        {
            if let dir = getDirectory(name: "experiences")
            {
                let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
                var result: [String] = []
                for file in contents
                {
                    let id = file.lastPathComponent
                    result.append("device:\(id)")
                }
                
                closure(result)
                return
            }
        }
        catch
        {
            NSLog("Error listing files")
        }
        
        closure([])
    }
    
    func saveExperience(_ experience: Experience, closure: @escaping(Result<Experience, Error>) -> Void)
    {
        var experience = experience
        var fileURL: URL?
        if canEdit(experience: experience)
        {
            fileURL = urlFor(experience.id)
        }
        else
        {
            if let dir = getDirectory(name: "experiences")
            {
                let id = NSUUID().uuidString
                fileURL = dir.appendingPathComponent(id)
                experience.id = "device:\(id)"
            }
        }
        
        if let text = experience.json
        {
            do
            {
                if let path = fileURL
                {
                    try text.write(to: path, atomically: false, encoding: .utf8)
                }
            }
            catch
            {
                NSLog("Error saving file at path: \(String(describing: fileURL)) with error: \(error): text: \(text)")
            }
        }
        else
        {
            NSLog("Error generating json")
        }
        
        closure(.success(experience))
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
            print("Couldn't get documents directory!")
        }
        
        return nil
    }
    
    func isSaving(experience: Experience) -> Bool
    {
        return false
    }
    
    func canEdit(experience: Experience) -> Bool
    {
        return id.hasPrefix("device:")
    }
}
