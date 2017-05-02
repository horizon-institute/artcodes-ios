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

class RecommendedViewController: ExperienceCollectionViewController, CLLocationManagerDelegate
{
	let locationManager = CLLocationManager()
	var location: CLLocation?
	var madeCall = false
    override var ordering: [String]
    {
        return ["recent", "starred", "nearby", "featured", "new", "popular"]
    }
    
    override init()
    {
		super.init()
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
        screenName = "View Recommended"
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
		
		if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
		{
			layout.headerReferenceSize = CGSize(width: 100, height: 40)
		}
	}
		
	override func viewWillAppear(_ animated: Bool)
	{
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			addExperienceURIs(appDelegate.server.recent, forGroup: "recent") {
				if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
				{
					appDelegate.drawerController.title = "Recent"
					appDelegate.drawerController.setCenterViewController(RecentViewController(), withCloseAnimation: true, completion: nil)
				}
			}
			//addExperienceURIs(appDelegate.server.starred, forGroup: "starred")
			self.collectionView.reloadData()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool)
	{
		locationManager.stopUpdatingLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
	{
		switch status
		{
		case CLAuthorizationStatus.restricted:
			NSLog("Restricted Access to location")
		case CLAuthorizationStatus.denied:
			NSLog("User denied access to location")
		case CLAuthorizationStatus.notDetermined:
			NSLog("Status not determined")
		default:
			NSLog("Allowed to location Access")
		}
		
		locationChanged(locationManager.location)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
	{
		NSLog("Recommended location update error: %@", "\(error)")
		locationChanged(nil)
	}
	
	func locationChanged(_ newLocation: CLLocation?)
	{
		if !madeCall
		{
			updateLocation(newLocation)
		}
		else if let location = newLocation
		{
			if let currentLocation = self.location
			{
				if currentLocation.distance(from: location) > 50
				{
					updateLocation(location)
				}
			}
			else
			{
				updateLocation(location)
			}
		}
	}
	
	func updateLocation(_ newLocation: CLLocation?)
	{
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			madeCall = true
			location = newLocation
			progress += 1
			appDelegate.server.loadRecommended(location?.coordinate) { (experiences) -> Void in

				for (key, experienceURIs) in experiences
				{
					self.addExperienceURIs(experienceURIs, forGroup: key)
				}
				self.progress -= 1
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
	{
		for newLocation in locations
		{
			locationChanged(newLocation)
			return
		}
	}
}
