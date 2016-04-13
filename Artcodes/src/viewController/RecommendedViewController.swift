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
        return ["recent", "nearby", "featured", "new", "popular"]
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
		
		if(!Feature.isEnabled("feature_hide_welcome"))
		{
			if let header = NSBundle.mainBundle().loadNibNamed("IntroductionView", owner: self, options: nil)[0] as? IntroductionView
			{
				header.dismiss = {
					Feature.enable("feature_hide_welcome")
					//self.collectionView.tableHeaderView = nil
				}
				header.more = {
					//		if let nsurl = ArtcodeAppDelegate.chromifyURL("http://aestheticodes.com/info/")
					//		{
					//			UIApplication.sharedApplication().openURL(nsurl)
					//		}
					self.navigationController?.pushViewController(AboutArtcodesViewController(), animated: true)
				}
				//tableView.tableHeaderView = header
			}
		}
		
		if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
		{
			layout.headerReferenceSize = CGSize(width: 100, height: 30)
		}
	}
	
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		sizeHeaderToFit()
	}
 
	func sizeHeaderToFit()
	{
//		if let headerView = tableView.tableHeaderView
//		{
//			headerView.setNeedsLayout()
//			headerView.layoutIfNeeded()
//		
//			let height = headerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
//			var frame = headerView.frame
//			frame.size.height = height
//			headerView.frame = frame
//		
//			tableView.tableHeaderView = headerView
//		}
	}
	
	override func viewWillAppear(animated: Bool)
	{
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			addExperienceURIs(appDelegate.server.recent, forGroup: "recent")
			self.collectionView.reloadData()
		}
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		locationManager.stopUpdatingLocation()
	}
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
	{
		switch status
		{
		case CLAuthorizationStatus.Restricted:
			NSLog("Restricted Access to location")
		case CLAuthorizationStatus.Denied:
			NSLog("User denied access to location")
		case CLAuthorizationStatus.NotDetermined:
			NSLog("Status not determined")
		default:
			NSLog("Allowed to location Access")
		}
		
		locationChanged(locationManager.location)
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
	{
		NSLog("Recommended location update error: \(error)")
		locationChanged(nil)
	}
	
	func locationChanged(newLocation: CLLocation?)
	{
		if !madeCall
		{
			updateLocation(newLocation)
		}
		else if let location = newLocation
		{
			if let currentLocation = self.location
			{
				if currentLocation.distanceFromLocation(location) > 50
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
	
	func updateLocation(newLocation: CLLocation?)
	{
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			madeCall = true
			location = newLocation
			progress++
			appDelegate.server.loadRecommended(location?.coordinate) { (experiences) -> Void in

				for (key, experienceURIs) in experiences
				{
					self.addExperienceURIs(experienceURIs, forGroup: key)
				}
				self.progress--
			}
		}
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
	{
		for newLocation in locations
		{
			locationChanged(newLocation)
			return
		}
	}
}