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
import artcodesScanner

class ArtcodeViewController: ScannerViewController
{
	let REQUIRED = 5
	let MAX = 20
	var action: Action?
	var markerCounts: [String: Int] = [:]
	
	override func markersDetected(markers: [AnyObject])
	{
		for (marker, count) in markerCounts
		{
			NSLog("\(marker) = \(count)")
			if count > MAX
			{
				markerCounts[marker] = MAX
			}
		}
		
		var removals: [String] = Array(markerCounts.keys)
		for marker in markers
		{
			if let markerCode = marker as? String
			{
				if let count = markerCounts[markerCode]
				{
					markerCounts[markerCode] = count + 1
				}
				else
				{
					markerCounts[markerCode] = 1
				}

				if let index = removals.indexOf(markerCode)
				{
					removals.removeAtIndex(index)
				}
			}
		}
		
		for marker in removals
		{
			if var count = markerCounts[marker]
			{
				count = count - 1
				if count == 0
				{
					markerCounts.removeValueForKey(marker)
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
			for code in action.codes
			{
				if let count = markerCounts[code]
				{
					if (count > best)
					{
						selected = action
						best = count
					}
				}
			}
		}
		
		if (selected == nil || best < REQUIRED)
		{
			if action != nil
			{
				action = nil
				actionChanged(nil)
			}
		}
		else if action == nil || selected!.name != action!.name
		{
			action = selected
			actionChanged(action)
		}
	}
	
	func actionChanged(action: Action?)
	{
		if action == nil
		{
			NSLog("No action")
		}
		else
		{
			NSLog("\(action!.name)")
		}
	}
}