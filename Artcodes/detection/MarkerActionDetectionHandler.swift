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

public class MarkerActionDetectionHandler: MarkerDetectionHandler {
	
	weak var callback: ActionDetectionHandler?
	let experience: Experience
	let MULTIPLE = 10
	let REQUIRED = 15
	let MAX = 60
	var action: Action?
	var markerCounts: [String: Int] = [:]
	
	public init(callback: ActionDetectionHandler, experience: Experience)
	{
		self.callback = callback
		self.experience = experience
	}
	
	@objc public func reset()
	{
		self.action = nil
		self.markerCounts.removeAll()
	}
	
	public func onMarkersDetected(markers: [Marker], scene: SceneDetails)
	{
		//let codes: [String] = markers.map({ $0.description })
        print("Marker Detected \(markers.map({ $0.name }))")
        
		for (marker, count) in markerCounts
		{
			if count > MAX
			{
				markerCounts[marker] = MAX
			}
		}
		
		var removals: [String] = Array(markerCounts.keys)
		for marker: Marker in markers
		{
			let markerCode = marker.name
			
			if let count = markerCounts[markerCode]
			{
				markerCounts[markerCode] = count + MULTIPLE
			}
			else
			{
				markerCounts[markerCode] = MULTIPLE
			}
			
            if let index = removals.firstIndex(of: markerCode)
			{
                removals.remove(at: index)
			}
		}
		
		for marker in removals
		{
			if var count = markerCounts[marker]
			{
				count = count - 1
				if count == 0
				{
                    markerCounts.removeValue(forKey: marker)
				}
				else
				{
					markerCounts[marker] = count
				}
			}
		}
		
		var best = 0
		var selected: Action?
		for action in experience.actions
		{
			if action.match == Match.any
			{
				for code in action.codes
				{
					if let score = markerCounts[code]
					{
						if (score > best)
						{
							selected = action
							best = score
						}
					}
				}
			}
			else if action.match == Match.all
			{
				var score = 0
				for code in action.codes
				{
					if let value = markerCounts[code]
					{
						if value > REQUIRED
						{
							score = score + value
						}
						else
						{
							score = 0
							break
						}
					}
					else
					{
						score = 0
						break
					}
				}
				if (score > best)
				{
					selected = action
					best = score
				}
			}
		}
		
		if (selected == nil || best < REQUIRED)
		{
			if action != nil
			{
				action = nil
                callback?.onMarkerActionDetected(detectedAction: action)
			}
		}
		else if action == nil || selected!.name != action!.name
		{
			action = selected
//			
//			var markerFound: Marker? = nil
//			for marker: Marker in markers
//			{
//				if (action!.codes.contains(marker.name))
//				{
//					markerFound = marker
//					break;
//				}
//			}
			
            callback?.onMarkerActionDetected(detectedAction: action)
            //(markerFound != nil && self.markerDrawer != nil ? [self.markerDrawer!.draw(marker: markerFound!, scene: scene)] : []))

		}
	}
	
	deinit {
		NSLog("*** Marker action detection handker deinit")
	}
}
