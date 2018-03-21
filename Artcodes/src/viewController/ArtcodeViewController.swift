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
		
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			if let id = experience.id
			{
				var recent = appDelegate.server.recent
				if recent.contains(id)
				{
					recent.removeObject(id)
				}
					
				recent.insert(id, at: 0)
				appDelegate.server.recent = recent
			}
		}
		
		self.takePictureButton.isHidden = false
	}
	
	func actionChanged(_ action: Action?)
	{
		//self.action = action
		if action == nil
		{
			//hideAction()
		}
		else
		{
			self.action = action
			if Feature.isEnabled("auto_open_markers")
			{
				openAction(self)
			}
			else
			{
				showAction()
			}
		}
	}
	
	func showAction()
	{
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			appDelegate.server.logInteraction(experience)
		}
		DispatchQueue.main.async(execute: {
			if let title = self.action?.name
			{
				self.actionButton.setTitle(title, for: .normal)
			}
			else if let url = self.action?.url
			{
				self.actionButton.setTitle(url, for: .normal)
			}
			else
			{
				return
			}
			self.actionButton.circleReveal(0.2)
			self.helpAnimation.isHidden = true
		})
	}
	
	func hideAction()
	{
		DispatchQueue.main.async(execute: {
			self.actionButton.circleHide(0.2)
			self.helpAnimation.isHidden = false
		})
	}
	
	@IBAction override func openAction(_ sender: AnyObject)
	{
		if var url = action?.url
		{
			url = url.replacingOccurrences(of: "{code}", with: action?.codes[0] ?? "")
			url = url.replacingOccurrences(of: "{timestamp}", with: String(Int(NSDate().timeIntervalSince1970)))
			url = url.replacingOccurrences(of: "{timehash1}", with: sha256(string: Hash.salts["timehash1"]!+String((Int(NSDate().timeIntervalSince1970)/1000)*1000)))
			
			NSLog("URL: %@", url)
			getMarkerDetectionHandler().reset()
			if (Feature.isEnabled("open_in_chrome"))
			{
				if let nsurl = ArtcodeAppDelegate.chromifyURL(url)
				{
					if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
					{
						appDelegate.server.logInteraction(experience)
					}
					UIApplication.shared.openURL(nsurl)
				}
			}
			else
			{
				if let nsurl = URL(string: url)
				{
					UIApplication.shared.openURL(nsurl)
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
				thumbnailViewController = ArtcodesThumbnailViewController(view: thumbnailView)
				self.markerDetectionHandler = MultipleCodeActionDetectionHandler(callback: self, experience: self.experience, markerDrawer: SquareMarkerDrawer())
			}
			else
			{
				self.markerDetectionHandler = MarkerActionDetectionHandler(callback: self, experience: self.experience, markerDrawer: nil)
			}
		}
		return self.markerDetectionHandler!
	}
	
	func onMarkerActionDetected(_ detectedAction: Action?, possibleFutureAction: Action?, imagesForFutureAction:[MarkerImage?]?)
	{
		self.actionChanged(detectedAction)
		if (self.thumbnailViewController != nil)
		{
			self.thumbnailViewController?.update(possibleFutureAction, incomingMarkerImages: imagesForFutureAction)
		}
	}
	
	@IBAction override func takePicture(_ sender: AnyObject)
	{
		super.takePicture(sender);
		self.frameProcessor?.takeScreenshots(CameraRollScreenshotSaver())
		self.displayMenuText("Images saved to camera roll")
	}
	
	func sha256(string: String) -> String{
		if let stringData = string.data(using: String.Encoding.utf8) {
			//return hexStringFromData(input: digest(input: stringData as NSData))
			
			let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
			var hash = [UInt8](repeating: 0, count: digestLength)
			var shaData: NSData? = nil
			stringData.withUnsafeBytes {(bytes: UnsafePointer<CChar>)->Void in
				CC_SHA256(bytes, UInt32(stringData.count), &hash)
				shaData = NSData(bytes: hash, length: digestLength)
			}
			
			if let input = shaData {
				var bytes = [UInt8](repeating: 0, count: input.length)
				input.getBytes(&bytes, length: input.length)
				var hexString = ""
				for byte in bytes {
					hexString += String(format:"%02x", UInt8(byte))
				}
				return hexString
			} else {
				return ""
			}
		}
		return ""
	}
}
