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

class AddCodeViewController: ScannerViewController, MarkerDetectionHandler
{
	let MULTIPLE = 3
	let REQUIRED = 15
	let MAX = 60
	var action: Action
	var markerCounts: [String: Int] = [:]
	
	init(action: Action)
	{
		self.action = action
		super.init(experience: Experience())
		experience.name = "Add Marker"
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		self.action = Action()
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
        if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
            var recent = appDelegate.server.recent
            if recent.contains(experience.id)
            {
                if let index = recent.firstIndex(of:experience.id) {
                    recent.remove(at: index)
                }
            }
                
            recent.insert(experience.id, at: 0)
            appDelegate.server.recent = recent
        }
	}
	
	internal func reset()
	{
		self.markerCounts.removeAll()
	}
	
	internal func onMarkersDetected(markers: [Marker], scene: SceneDetails)
	{
		var removals: [String] = Array(markerCounts.keys)
		for marker in markers
		{
			let markerCode: String = marker.name
			if let count = markerCounts[markerCode]
			{
				let newCount = count + MULTIPLE
				markerCounts[markerCode] = newCount
			}
			else
			{
				markerCounts[markerCode] = MULTIPLE
			}
			
            if let index = removals.firstIndex(of:markerCode)
			{
                removals.remove(at:index)
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
		var bestCode = ""
		for (marker, count) in markerCounts
		{
			if count > best
			{
				best = count
				bestCode = marker
			}
		}
		
		if best > REQUIRED
		{
            DispatchQueue.main.async {
                
                if self.action.codes.firstIndex(of:bestCode) == nil
                {
                    self.action.codes.append(bestCode)
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
			}
		}
	}
	
	override func getMarkerDetectionHandler() -> MarkerDetectionHandler
	{
		return self
	}
}
