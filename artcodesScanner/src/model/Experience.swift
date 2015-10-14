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

public class Experience
{
	public var actions = [Action]()
	public var availabilities = [Availability]()
	// TODO public var processors = [ImageProcessor]()
	public var id: String?
	public var name: String?
	public var icon: String?
	public var image: String?
	public var description: String?
	public var author: String?
	public var originalID: String?
	public var checksumModulo = 3
	public var embeddedChecksum = false
	public var editable = false
	
    public var markerSettings: MarkerSettings
    {
		let settings = MarkerSettings()
		settings.minRegions = 20
		settings.maxRegions = 0
		settings.maxRegionValue = 0
		
		for action in actions
		{
			for code in action.codes
			{
				let codeArr = code.characters.split{$0 == ":"}
				settings.minRegions = min(settings.minRegions, codeArr.count)
				settings.maxRegions = max(settings.maxRegions, codeArr.count)
				
				for codeValue in codeArr
				{
					if let codeNumber = Int(String(codeValue))
					{
						settings.maxRegionValue = max(settings.maxRegionValue, codeNumber)
					}
				}
			}
		}
		
		NSLog("Experience settings = \(settings.minRegions) - \(settings.maxRegions) Regions, < \(settings.maxRegionValue)")
		
        return settings
    }
    
	public init()
	{
	}
	
	public func update()
	{
	
	}
}