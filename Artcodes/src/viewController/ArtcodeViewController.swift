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

import Alamofire
import ArtcodesScanner
import Foundation

class ArtcodeViewController: ScannerViewController
{
	let MULTIPLE = 3
	let REQUIRED = 15
	let MAX = 60
	var action: Action?
	var markerCounts: [String: Int] = [:]
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			if let id = experience.id
			{
				var recent = appDelegate.server.recent
				if recent.contains(id)
				{
					recent.removeObject(id)
				}
					
				recent.insert(id, atIndex: 0)
				appDelegate.server.recent = recent
			}
		}
	}
	
	override func markersDetected(markers: [AnyObject])
	{
		for (marker, count) in markerCounts
		{
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
					markerCounts[markerCode] = count + MULTIPLE
				}
				else
				{
					markerCounts[markerCode] = MULTIPLE
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
			hideAction()
		}
		else
		{
			showAction()
		}
	}
	
	func showAction()
	{
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			appDelegate.server.logInteraction(experience)
		}
		dispatch_async(dispatch_get_main_queue(),{
			if let title = self.action?.name
			{
				self.actionButton.setTitle(title, forState: .Normal)
			}
			else if let url = self.action?.url
			{
				self.actionButton.setTitle(url, forState: .Normal)
			}
			else
			{
				return
			}
			self.actionButton.circleReveal(0.2)
		})
	}
	
	func hideAction()
	{
		dispatch_async(dispatch_get_main_queue(),{
			self.actionButton.circleHide(0.2)
		})
	}
	
	@IBAction override func openAction(sender: AnyObject)
	{
		if let url = action?.url
		{
			NSLog(url)
			markerCounts = [:]
			if let nsurl = ArtcodeAppDelegate.chromifyURL(url)
			{
				if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
				{
					appDelegate.server.logInteraction(experience)
				}
				UIApplication.sharedApplication().openURL(nsurl)
			}
		}
	}
}