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

public class MarkerCodeDetectionHandler: MarkerDetectionHandler {
	
	var callback: CodeDetectionHandler
	let MULTIPLE = 10
	let REQUIRED = 15
	let MAX = 60
	var markerCounts: [String: Int] = [:]
	
	public init(callback: CodeDetectionHandler)
	{
		self.callback = callback
	}
	
	@objc public func onMarkersDetected(markers: [Marker], scene: SceneDetails)
	{
		var removals: Set<String> = Set<String>(self.markerCounts.keys)
		
		for marker in markers
		{
			let markerCode: String = marker.description;
			self.markerCounts[markerCode] = (self.markerCounts[markerCode] ?? 0) + MULTIPLE
			removals.remove(markerCode)
		}
		
		for code: String in removals
		{
			let count: Int = self.markerCounts[code]!;
			if (count==1)
			{
				self.markerCounts.removeValueForKey(code)
			}
			else
			{
				self.markerCounts[code] = count-1
			}
		}
		
		var best: Int = 0
		var selected: String? = nil;
		
		for (code, count) in self.markerCounts
		{
			if (count > best)
			{
				selected = code
				best = count
			}
		}
		
		if (selected != nil && best >= REQUIRED)
		{
			self.callback.onCodeDetected(selected!)
		}
	}
	
	@objc public func reset()
	{
		self.markerCounts.removeAll()
	}
}