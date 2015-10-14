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
import Alamofire
import AlamofireImage
import artcodesScanner
import UIKit

class AvailabilityViewCell: UITableViewCell
{
	@IBOutlet weak var startButton: UIButton!
	@IBOutlet weak var endButton: UIButton!
	@IBOutlet weak var locationButton: UIButton!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var dashLabel: UILabel!
	
	let locationManager: CLLocationManager = CLLocationManager()
	let shortFormatter = NSDateFormatter()
	let longFormatter = NSDateFormatter()
	let calendar = NSCalendar.currentCalendar()
	
	var placePicker: GMSPlacePicker?
	var index: Int!
	var viewController: ExperienceEditAvailabilityViewController!
	var availability: Availability!
		{
		didSet
		{
			updateTime()
			updateLocation()
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		shortFormatter.dateFormat = "d MMM"
		longFormatter.dateFormat = "d MMM y"
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
	
	func formatDateRange(start: Int, end: Int) -> String
	{
		let startDate = NSDate(timeIntervalSince1970: Double(start) / 1000.0)
		let endDate = NSDate(timeIntervalSince1970: Double(end) / 1000.0)
		let startComponents = calendar.components([.Day, .Month, .Year], fromDate: startDate)
		let endComponents = calendar.components([.Day, .Month, .Year], fromDate: endDate)
		if startComponents.year == endComponents.year
		{
			if startComponents.month == endComponents.month
			{
				if startComponents.day == endComponents.day
				{
					return formatDate(start)
				}
				else
				{
					return "\(startComponents.day) – " + formatDate(end)
				}
			}
			else
			{
					return shortFormatter.stringFromDate(startDate) + " – " + formatDate(end)
			}
		}
		
		return longFormatter.stringFromDate(startDate) + " – " + longFormatter.stringFromDate(endDate)
	}
	
	func updateTime()
	{
		if let startTime = availability?.start
		{
			startButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
			startButton.setTitle(formatDate(startTime), forState: .Normal)
			if let endTime = availability?.end
			{
				timeLabel.text = "Available " + formatDateRange(startTime, end: endTime)
			}
			else
			{
				timeLabel.text = "Available from " + formatDate(startTime)
			}
		}
		else
		{
			startButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			startButton.setTitle("Start", forState: .Normal)
			if let endTime = availability?.end
			{
				timeLabel.text = "Available until " + formatDate(endTime)
			}
			else
			{
				timeLabel.text = "Always Available"
			}
		}
		
		if let endTime = availability?.end
		{
			endButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
			endButton.setTitle(formatDate(endTime), forState: .Normal)
		}
		else
		{
			endButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
			endButton.setTitle("End", forState: .Normal)
		}
	}
	
	@IBAction func deleteAvailability(sender: AnyObject)
	{
		viewController.deleteAvailability(index)
	}
	
	func updateLocation()
	{
		if let location = availability?.name
		{
			locationButton.setTitle(location, forState: .Normal)
		}
		else
		{
			locationButton.setTitle("Anywhere", forState: .Normal)
		}
	}
	
	func createViewport(lat: Double, lon: Double) -> GMSCoordinateBounds
	{
		let neLocation = CLLocationCoordinate2DMake(lat + 0.001, lon + 0.001)
		let swLocation = CLLocationCoordinate2DMake(lat - 0.001, lon - 0.001)
		return GMSCoordinateBounds(coordinate: neLocation, coordinate: swLocation)
	}
	
	@IBAction func pickPlace(sender: UILabel)
	{
		locationManager.requestWhenInUseAuthorization()
		
		var viewport = createViewport(52.9533076, lon: -1.18736)
		if let lat = availability?.lat, lon = availability?.lon
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
				self.availability?.name = place.name
				self.availability?.address = place.formattedAddress
				self.availability?.lat = place.coordinate.latitude
				self.availability?.lon = place.coordinate.longitude
				self.updateLocation()
			}
			else
			{
				NSLog("No place selected")
			}
		})
	}
	
	override func setSelected(selected: Bool, animated: Bool)
	{
		timeLabel.hidden = selected
		dashLabel.hidden = !selected
		startButton.hidden = !selected
		endButton.hidden = !selected
	}
	
	@IBAction func pickStart(sender: UILabel)
	{
		// Localization
		var start = NSDate()
		if let startTime = availability?.start
		{
			let doubleTime = Double(startTime) / 1000.0
			start = NSDate(timeIntervalSince1970: doubleTime)
		}

		ActionSheetDatePicker.showPickerWithTitle("Start Date", datePickerMode: .Date, selectedDate: start,  doneBlock: {
			picker, value, index in
			
			if let date = value as? NSDate
			{
				self.availability?.start = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
		}, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
	}
	
	@IBAction func pickEnd(sender: UILabel)
	{
		// Localization
		var end = NSDate()
		if let endTime = availability?.end
		{
			let doubleTime = Double(endTime) / 1000.0
			end = NSDate(timeIntervalSince1970: doubleTime)
		}
		
		ActionSheetDatePicker.showPickerWithTitle("End Date", datePickerMode: .Date, selectedDate: end,  doneBlock: {
			picker, value, index in
			
			if let date = value as? NSDate
			{
				self.availability?.end = Int(date.timeIntervalSince1970 * 1000)
				self.updateTime()
			}
			return
			}, cancelBlock: { ActionStringCancelBlock in return }, origin: sender)
	}
}
