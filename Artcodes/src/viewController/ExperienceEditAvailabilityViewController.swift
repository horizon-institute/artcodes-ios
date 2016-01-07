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

class ExperienceEditAvailabilityViewController: ExperienceEditBaseViewController, UITableViewDataSource, UITableViewDelegate
{
	@IBOutlet weak var tableView: UITableView!
	
	override var name: String
	{
		return "Availability"
	}
	
	init()
	{
		super.init(nibName:"ExperienceEditAvailabilityViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 56.0
		
		let actionNib = UINib(nibName: "AvailabilityViewCell", bundle:nil)
		tableView.registerNib(actionNib, forCellReuseIdentifier: "AvailabilityViewCell")
		
		let nibName = UINib(nibName: "NavigationMenuViewCell", bundle:nil)
		tableView.registerNib(nibName, forCellReuseIdentifier: "NavigationMenuViewCell")
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		if indexPath.item >= experience.availabilities.count
		{
			if indexPath.item == 0
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("NavigationMenuViewCell") as! NavigationMenuViewCell
				cell.navigationTitle.text = "Private"
				cell.navigationIcon.image = UIImage(named: "ic_lock_outline_18pt")
				return cell;
			}
			else
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("NavigationMenuViewCell") as! NavigationMenuViewCell
				cell.navigationTitle.text = "Add Availability"
				cell.navigationIcon.image = UIImage(named: "ic_add_18pt")
				return cell;
			}
		}
		let cell = tableView.dequeueReusableCellWithIdentifier("AvailabilityViewCell") as! AvailabilityViewCell
		cell.availability = experience.availabilities[indexPath.item]
		cell.index = indexPath.item
		cell.viewController = self
		return cell;
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if indexPath.item >= experience.availabilities.count && indexPath.item != 0
		{
			experience.availabilities.append(Availability())
			tableView.reloadData()
		}
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if experience.availabilities.count == 0
		{
			return 2
		}
		return experience.availabilities.count + 1
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func deleteAvailability(index: Int)
	{
		experience.availabilities.removeAtIndex(index)
		tableView.reloadData()
	}
}