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
    
    var name: String
    {
        return "Device"
    }
    
    func loadLibrary(closure: ([String]) -> Void)
    {
		let fileManager = NSFileManager.defaultManager()
		do
		{
			if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
			{
				let contents = try fileManager.contentsOfDirectoryAtPath(dir as String)
				var result: [String] = []
				for file in contents
				{
					let fileURL = NSURL(fileURLWithPath: dir.stringByAppendingPathComponent(file))
					let urlString = fileURL.absoluteString
					result.append(urlString)
					NSLog("\(urlString)")
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
			let uuid = NSUUID().UUIDString
			
			if let dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
			{
				fileURL = NSURL(fileURLWithPath: dir.stringByAppendingPathComponent(uuid))
				experience.id = fileURL?.absoluteString
			}
		}
		
		if let text = experience.json.rawString()
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
				NSLog("Error saving experience")
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
			if let url = NSURL(string: id)
			{
				return url.fileURL
			}
		}
		return false
	}
}