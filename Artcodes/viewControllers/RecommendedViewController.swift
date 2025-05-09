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
import UIKit
import CoreLocation

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
        
        // TODO screenName = "View Recommended"
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        {
            layout.headerReferenceSize = CGSize(width: 100, height: 40)
        }
    }
        
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
        {
            addExperienceURIs(experienceURIs: appDelegate.server.recent, forGroup: "recent") {
                if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
                {
                    appDelegate.menu.title = "Recent"
                    appDelegate.menu.show(RecentViewController(), sender: nil)
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
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
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
        
        DispatchQueue.main.async {
            self.locationChanged(newLocation: self.locationManager.location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error)
    {
        NSLog("Recommended location update error: %@", "\(error)")
        DispatchQueue.main.async {
            self.locationChanged(newLocation: nil)
        }
    }
    
    func locationChanged(newLocation: CLLocation?)
    {
        if !madeCall
        {
            updateLocation(newLocation: newLocation)
        }
        else if let location = newLocation
        {
            if let currentLocation = self.location
            {
                if currentLocation.distance(from: location) > 50
                {
                    updateLocation(newLocation: location)
                }
            }
            else
            {
                updateLocation(newLocation: location)
            }
        }
    }
    
    func updateLocation(newLocation: CLLocation?)
    {
        if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
        {
            madeCall = true
            location = newLocation
            progress += 1
            appDelegate.server.loadRecommended(near: location?.coordinate) { (experiences) -> Void in

                for (key, experienceURIs) in experiences
                {
                    self.addExperienceURIs(experienceURIs: experienceURIs, forGroup: key)
                }
                self.progress -= 1
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        DispatchQueue.main.async {
            self.locationChanged(newLocation: locations.last)
        }
    }
}
