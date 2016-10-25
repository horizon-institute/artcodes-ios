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

import ActionSheetPicker_3_0
import UIKit
import ArtcodesScanner
import GooglePlacePicker

class AvailabilityEditViewController: UIViewController
{
	@IBOutlet weak var scrollView: UIScrollView!

	@IBOutlet weak var startDate: UIButton!
	@IBOutlet weak var endDate: UIButton!
	
	@IBOutlet weak var location: UILabel!
	@IBOutlet weak var address: UILabel!
	
	let locationManager: CLLocationManager = CLLocationManager()
	let shortFormatter = NSDateFormatter()
	let longFormatter = NSDateFormatter()
	let calendar = NSCalendar.currentCalendar()
	
	var placePicker: GMSPlacePicker?
	
	var viewController: AvailabilityListViewController!
	let availability: Availability
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
		if let startTime = availability.start
		{
			startDate.setTitleColor(UIColor.blackColor(), forState: .Normal)
			startDate.setTitle(formatDate(startTime), forState: .Normal)
		}
		else
		{
			startDate.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			startDate.setTitle("Start", forState: .Normal)
		}
		
		if let endTime = availability.end
		{
			endDate.setTitleColor(UIColor.blackColor(), forState: .Normal)
			endDate.setTitle(formatDate(endTime), forState: .Normal)
		}
		else
		{
			endDate.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			endDate.setTitle("End", forState: .Normal)
		}
	}
	
	func formatDate(timestamp: Int) -> String
	{
		let date = NSDate(timeIntervalSince1970: Double(timestamp) / 1000.0)
		let currentYear = calendar.component(.Year, fromDate: NSDate())
		let year = calendar.component(.Year, fromDate: date)
		if year == currentYear
		{
			return shortFormatter.stringFromDate(date)
		}
		return longFormatter.stringFromDate(date)
	}
	
	func updateLocation()
	{
		if let locationName = availability.name
		{
			location.text = locationName
			address.text = availability.address
		}
		else
		{
			location.text = "Anywhere"
			address.text = ""
		}
	}
	
	func createViewport(lat: Double, lon: Double) -> GMSCoordinateBounds
	{
		let neLocation = CLLocationCoordinate2DMake(lat + 0.001, lon + 0.001)
		let swLocation = CLLocationCoordinate2DMake(lat - 0.001, lon - 0.001)
		return GMSCoordinateBounds(coordinate: neLocation, coordinate: swLocation)
	}
	
	@IBAction func deleteAvailability(sender: AnyObject)
	{
		presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
			self.viewController.deleteAvailability(self.index)
		})
	}
	
	@IBAction func close(sender: AnyObject)
	{
		viewController?.tableView.reloadData()
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func pickPlace(sender: AnyObject)
	{
		locationManager.requestWhenInUseAuthorization()
		
		var viewport = createViewport(52.9533076, lon: -1.18736)
		if let lat = availability.lat, lon = availability.lon
		{
			viewport = createViewport(lat, lon: lon)
		}
		else if let location = locationManager.location
		{
			viewport = createViewport(location.coordinate.latitude, lon: location.coordinate.longitude)
		}
		
		let config = GMSPlacePickerConfig(viewport: viewport)
		placePicker = GMSPlacePicker(config: config)
		placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error: NSError?) -> Void in
			if let error = error
			{
				NSLog("Pick Place error: \(error.localizedDescription)")
				return
			}
			
			if let place = place
			{
				self.availability.name = place.name
				self.availability.address = place.formattedAddress
				self.availability.lat = place.coordinate.latitude
				self.availability.lon = place.coordinate.longitude
				self.updateLocation()
			}
			else
			{
				NSLog("No place selected")
			}
		})
	}
	
	@IBAction func pickStart(sender: UIButton)
	{
		// Localization
		var start = NSDate()
		if let startTime = availability.start
		{
			let doubleTime = Double(startTime) / 1000.0
			start = NSDate(timeIntervalSince1970: doubleTime)
		}
		
		ActionSheetDatePicker.showPickerWithTitle("Start Date", datePickerMode: .Date, selectedDate: start,  doneBlock: {
			picker, value, index in
			
			if let date = value as? NSDate
			{
				self.availability.start = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
			}, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
	}
	
	@IBAction func pickEnd(sender: UIButton)
	{
		// Localization
		var end = NSDate()
		if let endTime = availability.end
		{
			let doubleTime = Double(endTime) / 1000.0
			end = NSDate(timeIntervalSince1970: doubleTime)
		}
		
		ActionSheetDatePicker.showPickerWithTitle("End Date", datePickerMode: .Date, selectedDate: end,  doneBlock: {
			picker, value, index in
			
			if let date = value as? NSDate
			{
				self.availability.end = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
			}, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
	}
}
