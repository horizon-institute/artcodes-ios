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
	let REQUIRED = 5
	let MAX = 20
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
			let origin = self.actionButton.center
			let mask = CAShapeLayer()
			mask.path = self.makeCirclePath(origin, radius: 0)
			mask.fillColor = UIColor.blackColor().CGColor
			
			self.actionButton.layer.mask = mask
			
			CATransaction.begin()
			let animation = CABasicAnimation(keyPath: "path")
			animation.duration = 0.5
			animation.fillMode = kCAFillModeForwards
			animation.removedOnCompletion = false
			
			let newPath = self.makeCirclePath(origin, radius:CGRectGetWidth(self.actionButton.bounds) + 20)
			animation.fromValue = mask.path
			animation.toValue = newPath
			
			CATransaction.setCompletionBlock() {
				self.actionButton.layer.mask = nil;
			}
			
			mask.addAnimation(animation, forKey:"path")
			CATransaction.commit()
			
			self.actionButton.hidden = false
			self.activity.hidden = true
		})
	}
	
	func hideAction()
	{
		dispatch_async(dispatch_get_main_queue(),{
			let origin = self.actionButton.center
			let mask = CAShapeLayer()
			mask.path = self.makeCirclePath(origin, radius:CGRectGetWidth(self.actionButton.bounds) + 20)
			mask.fillColor = UIColor.blackColor().CGColor
			
			self.actionButton.layer.mask = mask
			
			CATransaction.begin()
			let animation = CABasicAnimation(keyPath: "path")
			animation.duration = 0.5
			animation.fillMode = kCAFillModeForwards
			animation.removedOnCompletion = false
			
			let newPath = self.makeCirclePath(origin, radius:0)
			
			animation.fromValue = mask.path
			animation.toValue = newPath
			
			CATransaction.setCompletionBlock() {
				self.actionButton.hidden = true
				self.actionButton.layer.mask = nil
				self.activity.hidden = false
			}
			mask.addAnimation(animation, forKey:"path")
			CATransaction.commit()
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
				if let id = experience.id
				{
					Alamofire.request(.POST, "https://aestheticodes.appspot.com/interaction", parameters: ["experience": id])
				}
				UIApplication.sharedApplication().openURL(nsurl)
			}
		}
	}
}