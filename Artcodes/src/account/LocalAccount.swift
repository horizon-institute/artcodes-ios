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
		if uri != nil && uri!.hasPrefix("device:")
		{
			if let dir = ArtcodeAppDelegate.getDirectory("experiences")
			{
				return dir.appendingPathComponent(uri!.substring(from: uri!.characters.index(uri!.startIndex, offsetBy: 7)))
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
	
	func deleteExperience(_ experience: Experience)
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
	
	func requestFor(_ uri: String) -> URLRequest?
	{
		if let url = urlFor(uri)
		{
			return URLRequest(url: url)
		}
		return nil
	}
	
    func loadLibrary(_ closure: ([String]) -> Void)
    {
		let fileManager = FileManager.default
		do
		{
			if let dir = ArtcodeAppDelegate.getDirectory("experiences")
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
	
	func saveExperience(_ experience: Experience)
	{
		var fileURL: URL?
		if canEdit(experience)
		{
			fileURL = urlFor(experience.id)
		}
		else
		{
			if experience.id != nil
			{
				experience.originalID = experience.id
			}
			
			if let dir = ArtcodeAppDelegate.getDirectory("experiences")
			{
				let id = UUID().uuidString
				fileURL = dir.appendingPathComponent(id)
				experience.id = "device:\(id)"
			}
		}
		
		if let text = experience.json.rawString(options:JSONSerialization.WritingOptions())
		{
			do
			{
				if fileURL != nil
				{
					let path = fileURL!.path
					try text.write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
				}
			}
			catch
			{
				NSLog("Error saving file at path: %@ with error: %@: text: %@", "\(fileURL)", "\(error)", "\(text)")
			}
		}
		else
		{
			NSLog("Error generating json")
		}
		
		if let callback = experience.callback
		{
			callback()
		}
	}
	
	func isSaving(_ experience: Experience) -> Bool
	{
		return false
	}
	
	func canEdit(_ experience: Experience) -> Bool
	{
		if let id = experience.id
		{
			return id.hasPrefix("device:")
		}
		return false
	}
}
