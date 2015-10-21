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

@objc
public class DetectionSettings: NSObject
{
	public let minRegions: Int
	public let maxRegions: Int
	public let maxRegionValue: Int
	public let checksumModulo: Int
	public let embeddedChecksum: Bool
	public let validCodes: Set<String>
	public var detected = false
	public var handler: (markers: [String]) -> Void = { arg in }

	public var displayText = 0
	public var displayOutline = 0
	public var displayThreshold = 0
	
	public init(experience: Experience)
	{
		var minRegions = 20
		var maxRegions = 0
		var maxRegionValue = 0
		var codeSet = Set<String>()
		
		for action in experience.actions
		{
			for code in action.codes
			{
				let codeArr = code.characters.split{$0 == ":"}
				minRegions = min(minRegions, codeArr.count)
				maxRegions = max(maxRegions, codeArr.count)
				
				for codeValue in codeArr
				{
					if let codeNumber = Int(String(codeValue))
					{
						maxRegionValue = max(maxRegionValue, codeNumber)
					}
				}
				
				codeSet.insert(code)
			}
		}

		NSLog("Experience settings = \(minRegions) - \(maxRegions) Regions, < \(maxRegionValue)")
		self.maxRegions = maxRegions
		self.minRegions = minRegions
		self.maxRegionValue = maxRegionValue
		self.checksumModulo = experience.checksumModulo
		self.embeddedChecksum = experience.embeddedChecksum
		
		self.validCodes = Set(codeSet)
	}
	
	
    public func isValid(marker: NSArray?, withEmbeddedChecksum embeddedChecksum: NSNumber?) -> Bool
    {
        if let markerCode = marker as? [Int]
        {
            if markerCode.count < minRegions
            {
                return false
            }
            
            if markerCode.count > maxRegions
            {
                return false
            }
            
            for value in markerCode
            {
                if value > maxRegionValue
                {
                    return false
                }
            }
            
            // TODO
            //if (embeddedChecksum == null && !hasValidChecksum(markerCodes))
            //{
            //	return false; // Region Total not Divisable by checksumModulo
            //}
            //else if (this.embeddedChecksum && embeddedChecksum != null && !hasValidEmbeddedChecksum(markerCodes, embeddedChecksum))
            //{
            //	return false; // Region Total not Divisable by embeddedChecksum
            //}
            //else if (!this.embeddedChecksum && embeddedChecksum != null)
            //{
            // Embedded checksum is turned off yet one was provided to this function (this should never happen unless the settings are changed in the middle of detection)
            //	return false; // Embedded checksum markers are not valid.
            //}
            
            return true
        }
        return false
    }
}