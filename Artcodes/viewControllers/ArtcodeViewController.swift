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
import UIKit

class ArtcodeViewController: ScannerViewController, ActionDetectionHandler
{
    var action: Action?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
        {
            var recent = appDelegate.server.recent
            if recent.contains(experience.id)
            {
                if let index = recent.firstIndex(of: experience.id) {
                    recent.remove(at: index)
                }
            }
                
            recent.insert(experience.id, at: 0)
            appDelegate.server.recent = recent
        }
        
        self.takePictureButton.isHidden = false
    }
    
    func actionChanged(action: Action?)
    {
        print("Action Changed to \(action?.name ?? "None")")
        //self.action = action
        if action == nil
        {
            //hideAction()
        }
        else
        {
            self.action = action
            if Feature.isEnabled(feature: "auto_open_markers")
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
            appDelegate.server.logInteraction(experience: experience)
        }
        DispatchQueue.main.async {
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
            self.actionButton.circleReveal(speed: 0.2)
            self.helpAnimation.isHidden = true
        }
    }
    
    func hideAction()
    {
        DispatchQueue.main.async {
            self.actionButton.circleHide(speed: 0.2)
            self.helpAnimation.isHidden = false
        }
    }
    
    @IBAction override func openAction(_ sender: Any)
    {
        if let url = action?.url
        {
            NSLog("URL: %@", url)
            getMarkerDetectionHandler().reset()
            if (Feature.isEnabled(feature: "open_in_chrome"))
            {
                if let nsurl = chromifyURL(url: url)
                {
                    if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
                    {
                        appDelegate.server.logInteraction(experience: experience)
                    }
                    UIApplication.shared.open(nsurl)
                }
            }
            else
            {
                if let nsurl = URL(string: url)
                {
                    UIApplication.shared.open(nsurl)
                }
            }
        }
    }
    
    static let googleChromeHTTPScheme: String = "googlechrome:"
    static let googleChromeHTTPSScheme: String = "googlechromes:"
    
    func chromifyURL(url: String) -> URL?
    {
        var alteredURL = url
        if alteredURL.hasPrefix("http://")
        {
            alteredURL = alteredURL.replacingOccurrences(of: "http://", with: ArtcodeViewController.googleChromeHTTPScheme)
        }
        else if alteredURL.hasPrefix("https://")
        {
            alteredURL = alteredURL.replacingOccurrences(of: "https://", with: ArtcodeViewController.googleChromeHTTPSScheme)
        }
        
        if let testURL = URL(string: alteredURL)
        {
            if(UIApplication.shared.canOpenURL(testURL))
            {
                NSLog("Using %@", alteredURL)
                return testURL
            }
        }
        
        NSLog("Using %@", url)
        return URL(string: url)
    }
        
    
    //var thumbnailViewController: ArtcodesThumbnailViewController? = nil
    override func getMarkerDetectionHandler() -> MarkerDetectionHandler
    {
        if (self.markerDetectionHandler == nil)
        {
            if Feature.isEnabled(feature: "feature_combined_codes")
            {
                //thumbnailViewController = ArtcodesThumbnailViewController(view: thumbnailView)
                self.markerDetectionHandler = MarkerActionDetectionHandler(callback: self, experience: self.experience)
                //self.markerDetectionHandler = MultipleCodeActionDetectionHandler(callback: self, experience: self.experience, markerDrawer: SquareMarkerDrawer())
            }
            else
            {
                self.markerDetectionHandler = MarkerActionDetectionHandler(callback: self, experience: self.experience)
            }
        }
        return self.markerDetectionHandler!
    }
    
    func onMarkerActionDetected(detectedAction: Action?)
    {
        DispatchQueue.main.async {
            self.actionChanged(action: detectedAction)
        }
//        if (self.thumbnailViewController != nil)
//        {
//            self.thumbnailViewController?.update(currentOrFutureAction: possibleFutureAction, incomingMarkerImages: imagesForFutureAction)
//        }
    }
    
    @IBAction override func takePicture(_ sender: Any)
    {
        super.takePicture(sender);
        //self.frameProcessor?.takeScreenshots(CameraRollScreenshotSaver())
        self.displayMenuText(text: "Images saved to camera roll")
    }
}
