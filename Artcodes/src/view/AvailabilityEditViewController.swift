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

class AvailabilityEditViewController: UIViewController, GMSPlacePickerViewControllerDelegate
{
	@IBOutlet weak var scrollView: UIScrollView!

	@IBOutlet weak var startDate: UIButton!
	@IBOutlet weak var endDate: UIButton!
	
	@IBOutlet weak var location: UILabel!
	@IBOutlet weak var address: UILabel!
	
	let locationManager: CLLocationManager = CLLocationManager()
	let shortFormatter = DateFormatter()
	let longFormatter = DateFormatter()
	let calendar = Calendar.current
	
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
			startDate.setTitleColor(UIColor.black, for: UIControlState())
			startDate.setTitle(formatDate(startTime), for: .normal)
		}
		else
		{
			startDate.setTitleColor(UIColor.lightGray, for: UIControlState())
			startDate.setTitle("Start", for: UIControlState())
		}
		
		if let endTime = availability.end
		{
			endDate.setTitleColor(UIColor.black, for: UIControlState())
			endDate.setTitle(formatDate(endTime), for: .normal)
		}
		else
		{
			endDate.setTitleColor(UIColor.lightGray, for: UIControlState())
			endDate.setTitle("End", for: UIControlState())
		}
	}
	
	func formatDate(_ timestamp: Int) -> String
	{
		let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
		let currentYear = (calendar as NSCalendar).component(.year, from: Date())
		let year = (calendar as NSCalendar).component(.year, from: date)
		if year == currentYear
		{
			return shortFormatter.string(from: date)
		}
		return longFormatter.string(from: date)
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
	
	func createViewport(_ lat: Double, lon: Double) -> GMSCoordinateBounds
	{
		let neLocation = CLLocationCoordinate2DMake(lat + 0.001, lon + 0.001)
		let swLocation = CLLocationCoordinate2DMake(lat - 0.001, lon - 0.001)
		return GMSCoordinateBounds(coordinate: neLocation, coordinate: swLocation)
	}
	
	@IBAction func deleteAvailability(_ sender: AnyObject)
	{
		presentingViewController?.dismiss(animated: true, completion: { () -> Void in
			self.viewController.deleteAvailability(self.index)
		})
	}
	
	@IBAction func close(_ sender: AnyObject)
	{
		viewController?.tableView.reloadData()
		presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func pickPlace(_ sender: AnyObject)
	{
		locationManager.requestWhenInUseAuthorization()
		
		var viewport = createViewport(52.9533076, lon: -1.18736)
		if let lat = availability.lat, let lon = availability.lon
		{
			viewport = createViewport(lat, lon: lon)
		}
		else if let location = locationManager.location
		{
			viewport = createViewport(location.coordinate.latitude, lon: location.coordinate.longitude)
		}
		
		let config = GMSPlacePickerConfig(viewport: viewport)
		
		let ppvc = GMSPlacePickerViewController(config: config)
		ppvc.delegate = self
		present(ppvc, animated: true, completion: {() -> Void in })
	}
	
	func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace)
	{
		self.availability.name = place.name
		self.availability.address = place.formattedAddress
		self.availability.lat = place.coordinate.latitude
		self.availability.lon = place.coordinate.longitude
		self.updateLocation()
		viewController.dismiss(animated: true, completion: nil)
	}
	
	func placePicker(_ viewController: GMSPlacePickerViewController, didFailWithError error: Error) {
		NSLog("An error occurred while picking a place: \(error)")
		viewController.dismiss(animated: true, completion: nil)
	}
	
	func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
		NSLog("The place picker was canceled by the user")
		viewController.dismiss(animated: true, completion: nil)
	}
		
		
	
	@IBAction func pickStart(_ sender: UIButton)
	{
		// Localization
		var start = Date()
		if let startTime = availability.start
		{
			let doubleTime = Double(startTime) / 1000.0
			start = Date(timeIntervalSince1970: doubleTime)
		}
		
		ActionSheetDatePicker.show(withTitle: "Start Date", datePickerMode: .date, selectedDate: start,  doneBlock: {
			picker, value, index in
			
			if let date = value as? Date
			{
				self.availability.start = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
			}, cancel: { ActionStringCancelBlock in return }, origin: sender)
	}
	
	@IBAction func pickEnd(_ sender: UIButton)
	{
		// Localization
		var end = Date()
		if let endTime = availability.end
		{
			let doubleTime = Double(endTime) / 1000.0
			end = Date(timeIntervalSince1970: doubleTime)
		}
		
		ActionSheetDatePicker.show(withTitle: "End Date", datePickerMode: .date, selectedDate: end,  doneBlock: {
			picker, value, index in
			
			if let date = value as? Date
			{
				self.availability.end = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
			}, cancel: { ActionStringCancelBlock in return }, origin: sender)
	}
}
