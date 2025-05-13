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
import UIKit
import ArtcodesScanner
import UIKit
import CoreLocation
import LocationPicker
import MapKit

class AvailabilityEditViewController: UIViewController
{
    @IBOutlet var startDate: UILabel!
    @IBOutlet var startPicker: UIDatePicker!
    @IBOutlet var startClear: UIButton!
    
    @IBOutlet var endDate: UILabel!
    @IBOutlet var endPicker: UIDatePicker!
    @IBOutlet var endClear: UIButton!
    
	@IBOutlet var location: UILabel!
	@IBOutlet var address: UILabel!
    @IBOutlet var placeClear: UIButton!
	
	let locationManager: CLLocationManager = CLLocationManager()
	let shortFormatter = DateFormatter()
	let longFormatter = DateFormatter()
	let calendar = Calendar.current
		
	var viewController: AvailabilityListViewController!
	var availability: Availability
	let index: Int
	
	init(action: Availability, index: Int)
	{
		self.availability = action
		self.index = index
		super.init(nibName:"AvailabilityEditViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		availability = Availability()
		index = 0
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		shortFormatter.dateFormat = "d MMM"
		longFormatter.dateFormat = "d MMM y"
		
		updateTime()
		updateLocation()
	}
	
	func updateTime()
	{
        startPicker.minimumDate = Date()
        endPicker.minimumDate = Date()
		if let start = availability.start
		{
            endPicker.minimumDate = start
            //startDate.setTitleColor(UIColor.black, for: .normal)
            startDate.text = "Starts " + formatDate(date: start)
            if #available(iOS 13.0, *) {
                startDate.textColor = .label
            } else {
                startDate.textColor = .black
            }
            print("Start = \(startDate.text ?? "None")")
            startClear.isHidden = false
		}
		else
		{
            endPicker.minimumDate = Date()
            //startDate.setTitleColor(UIColor.lightGray, for: .normal)
            startDate.text = "No Start Date"
            if #available(iOS 13.0, *) {
                startDate.textColor = .secondaryLabel
            } else {
                startDate.textColor = .gray
            }
            startClear.isHidden = true
		}
		
		if let end = availability.end
		{
            startPicker.maximumDate = end
            //endDate.setTitleColor(UIColor.black, for: .normal)
            endDate.text = "Ends " + formatDate(date: end)
            if #available(iOS 13.0, *) {
                endDate.textColor = .label
            } else {
                endDate.textColor = .black
            }
            endClear.isHidden = false
            print("End = \(endDate.text ?? "None")")
		}
		else
		{
            startPicker.maximumDate = nil
            //endDate.setTitleColor(UIColor.lightGray, for: .normal)
            endDate.text = "No End Date"
            if #available(iOS 13.0, *) {
                endDate.textColor = .secondaryLabel
            } else {
                endDate.textColor = .gray
            }
            endClear.isHidden = true
		}
	}
	
    func formatDate(date: Date) -> String
	{
        let currentYear = calendar.component(.year, from: Date())
        let year = calendar.component(.year, from: date)
		if year == currentYear
		{
            return shortFormatter.string(from: date)
		}
        return longFormatter.string(from: date)
	}
	
	func updateLocation()
	{
        if let locationName = availability.location?.name
		{
			location.text = locationName
            address.text = availability.location?.address
            placeClear.isHidden = false
		}
		else
		{
			location.text = "Anywhere"
			address.text = ""
            placeClear.isHidden = true
		}
	}
	
    @IBAction func startChanged(_ sender: Any)
    {
        availability.start = startPicker.date
        updateTime()
    }
    
    @IBAction func startClear(_ sender: Any)
    {
        availability.start = nil
        updateTime()
    }
    
    @IBAction func endChanged(_ sender: Any)
    {
        availability.end = endPicker.date
        updateTime()
    }
    
    @IBAction func endClear(_ sender: Any)
    {
        availability.end = nil
        updateTime()
    }
    
	@IBAction func deleteAvailability(_ sender: Any)
	{
        presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            self.viewController.deleteAvailability(index: self.index)
		})
	}
	
	@IBAction func close(_ sender: Any)
	{
        viewController?.experience.availabilities[index] = availability
		viewController?.tableView.reloadData()
        presentingViewController?.dismiss(animated: true, completion: nil)
	}
    
    @IBAction func placeClear(_ sender: Any)
    {
        availability.location = nil
        updateLocation()
    }
	
	@IBAction func pickPlace(_ sender: Any)
	{
        print("Pick Place")
        let locationPicker = LocationPickerViewController()
        
        if let coordinates = availability.location?.coordinates {
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1]), addressDictionary: nil)
            let location = Location(name: availability.location?.name, location: nil, placemark: placemark)
            locationPicker.location = location
        }
        locationPicker.mapType = .standard
        locationPicker.useCurrentLocationAsHint = true
        locationPicker.searchBarPlaceholder = "Search Places"

        //locationPicker.showCurrentLocationButton = true // default: true
        //locationPicker.currentLocationButtonBackground = .blue
        //locationPicker.showCurrentLocationInitially = true // default: true
    
        locationPicker.completion = { location in
            if let place = location
            {
                self.dismiss(animated: true)
                var location = Location()
                location.address = place.address
                location.name = place.name
                location.coordinates = [place.coordinate.latitude, place.coordinate.longitude]
                self.availability.location = location
                self.updateLocation()
            }
            else
            {
                NSLog("No place selected")
            }
        }

        present(locationPicker, animated: true)
	}
}
