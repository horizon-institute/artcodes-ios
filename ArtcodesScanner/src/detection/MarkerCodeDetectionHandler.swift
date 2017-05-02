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

open class MarkerCodeDetectionHandler: MarkerDetectionHandler {
	
	let experience: Experience
	let closure: (String)->()
	let MULTIPLE = 10
	let REQUIRED = 15
	let MAX_MULTIPLIER = 4
	var markerCounts: [String: Int] = [:]
	
	public init(experience: Experience, closure: @escaping (String)->())
	{
		self.experience = experience
		self.closure = closure
	}
	
	@objc open func onMarkersDetected(_ markers: [Marker], scene: SceneDetails)
	{
		var removals: Set<String> = Set<String>(self.markerCounts.keys)
		
		for marker in markers
		{
			let markerCode: String = marker.description;
			self.markerCounts[markerCode] = min((self.markerCounts[markerCode] ?? 0) + self.awardFor(markerCode), maxFor(markerCode));
			removals.remove(markerCode)
		}
		
		for code: String in removals
		{
			let count: Int = self.markerCounts[code]!;
			if (count==1)
			{
				self.markerCounts.removeValue(forKey: code)
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
		
		if (selected != nil && best >= requiredFor(selected!))
		{
			self.closure(selected!)
		}
	}
	
	@objc open func reset()
	{
		self.markerCounts.removeAll()
	}
	
	fileprivate func awardFor(_ code: String) -> Int
	{
		if let action = self.experience.actionForCode(code)
		{
			if let award = action.framesAwarded
			{
				return award
			}
		}
		return MULTIPLE
	}
	
	fileprivate func requiredFor(_ code: String) -> Int
	{
		if let action = self.experience.actionForCode(code)
		{
			if let required = action.framesRequired
			{
				return required
			}
		}
		return REQUIRED
	}
	
	fileprivate func maxFor(_ code: String) -> Int
	{
		return self.requiredFor(code) * MAX_MULTIPLIER
	}
}
