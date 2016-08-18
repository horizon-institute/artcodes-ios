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

class ArtcodeViewController: ScannerViewController, ActionDetectionHandler
{
	var action: Action?
	
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
	
	func actionChanged(action: Action?)
	{
		//self.action = action
		if action == nil
		{
			//hideAction()
		}
		else
		{
			self.action = action
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
			self.getMarkerDetectionHandler().reset()
			if (Feature.isEnabled("open_in_chrome"))
			{
				if let nsurl = ArtcodeAppDelegate.chromifyURL(url)
				{
					if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
					{
						appDelegate.server.logInteraction(experience)
					}
					UIApplication.sharedApplication().openURL(nsurl)
				}
			}
			else
			{
				if let nsurl = NSURL(string: url)
				{
					UIApplication.sharedApplication().openURL(nsurl)
				}
			}
		}
	}
	
	var thumbnailViewController: ArtcodesThumbnailViewController? = nil
	override func getMarkerDetectionHandler() -> MarkerDetectionHandler
	{
		if (self.markerDetectionHandler == nil)
		{
			if Feature.isEnabled("feature_combined_codes")
			{
				thumbnailViewController = ArtcodesThumbnailViewController(view: self.getThumbnailView())
				self.markerDetectionHandler = MultipleCodeActionDetectionHandler(callback: self, experience: self.experience, markerDrawer: SquareMarkerDrawer())
			}
			else
			{
				self.markerDetectionHandler = MarkerActionDetectionHandler(callback: self, experience: self.experience, markerDrawer: nil)
			}
		}
		return self.markerDetectionHandler!
	}
	
	func onMarkerActionDetected(detectedAction: Action?, possibleFutureAction: Action?, imagesForFutureAction:[MarkerImage?]?)
	{
		self.actionChanged(detectedAction)
		if (self.thumbnailViewController != nil)
		{
			self.thumbnailViewController?.update(possibleFutureAction, incomingMarkerImages: imagesForFutureAction)
		}
	}
}