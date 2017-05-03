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
import TTGSnackbar
import ActionSheetPicker_3_0

class AvailabilityListViewController: ExperienceEditBaseViewController, UITableViewDataSource, UITableViewDelegate
{
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var emptyView: UIView!
	@IBOutlet weak var helpText: UILabel!
	
	override var name: String
	{
		return "Availability"
	}
	
	override var addEnabled: Bool
	{
		return true
	}
	
	init()
	{
		super.init(nibName:"AvailabilityListViewController", bundle:nil)
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
		tableView.register(actionNib, forCellReuseIdentifier: "AvailabilityViewCell")
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "AvailabilityViewCell") as! AvailabilityViewCell
		cell.availability = experience.availabilities[indexPath.item]
		cell.index = indexPath.item
		cell.viewController = self
		return cell;
	}
	
	override func add()
	{
		let availability = Availability()
		experience.availabilities.append(availability)
		tableView.reloadData()
		
		let vc = AvailabilityEditViewController(action: availability, index: experience.availabilities.count - 1)
		vc.viewController = self
		navigationController?.present(vc, animated: true, completion: nil)
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let availability = experience.availabilities[indexPath.item]
		let vc = AvailabilityEditViewController(action: availability, index: indexPath.item)
		vc.viewController = self
		
		
		modalPresentationStyle = UIModalPresentationStyle.formSheet
		self.present(vc, animated: true, completion: nil)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		emptyView.isHidden = !experience.availabilities.isEmpty
		helpText.isHidden = !experience.availabilities.isEmpty
		return experience.availabilities.count
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func deleteAvailability(_ index: Int)
	{
		experience.availabilities.remove(at: index)
		tableView.reloadData()
	}
}
