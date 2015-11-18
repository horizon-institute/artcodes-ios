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
	
    func loadLibrary(closure: ([String]) -> Void)
    {
		let fileManager = NSFileManager.defaultManager()
		do
		{
			if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
			{
				let contents = try fileManager.contentsOfDirectoryAtPath(dir)
				var result: [String] = []
				for file in contents
				{
					if file.characters.count == 36 && !file.hasPrefix(".")
					{
						result.append("device:\(file)")
					}
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
	
	func saveExperience(experience: Experience)
	{
		var fileURL: NSURL?
		if experience.id != nil
		{
			fileURL = NSURL(string: experience.id!)
		}
		
		if fileURL == nil || !fileURL!.fileURL
		{
			if experience.id != nil
			{
				experience.originalID = experience.id
			}
						
			if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
			{
				fileURL = NSURL(fileURLWithPath: dir.stringByAppendingPathComponent(NSUUID().UUIDString))
				experience.id = fileURL?.absoluteString
			}
		}
		
		experience.id = nil
		if let text = experience.json.rawString(options:NSJSONWritingOptions())
		{
			do
			{
				if fileURL != nil
				{
					if let path = fileURL!.path
					{
						try text.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
					}
				}
			}
			catch
			{
				NSLog("Error saving file at path: \(fileURL) with error: \(error): text: \(text)")
			}
		}
		else
		{
			NSLog("Error generating json")
		}
	}
	
	func canEdit(experience: Experience) -> Bool
	{
		if let id = experience.id
		{
			return id.hasPrefix("device:")
		}
		return false
	}
}