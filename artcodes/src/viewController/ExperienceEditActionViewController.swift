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

class ExperienceEditActionViewController: ExperienceEditBaseViewController, UITableViewDataSource, UITableViewDelegate
{
	@IBOutlet weak var tableView: UITableView!
	var selected: Int?
	
	override var name: String
	{
		return "Actions"
	}
	
	init()
	{
		super.init(nibName:"ExperienceEditActionViewController", bundle:nil)
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
	
		let actionNib = UINib(nibName: "ActionViewCell", bundle:nil)
		tableView.registerNib(actionNib, forCellReuseIdentifier: "ActionViewCell")

		let editNib = UINib(nibName: "ActionEditCell", bundle:nil)
		tableView.registerNib(editNib, forCellReuseIdentifier: "ActionEditCell")
		
		let urlNib = UINib(nibName: "ActionURLViewCell", bundle:nil)
		tableView.registerNib(urlNib, forCellReuseIdentifier: "ActionURLViewCell")
		
		let nibName = UINib(nibName: "NavigationMenuViewCell", bundle:nil)
		tableView.registerNib(nibName, forCellReuseIdentifier: "NavigationMenuViewCell")
	}
	
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if indexPath.item >= experience.actions.count
		{
			experience.actions.append(Action())
			selected = indexPath.item
		}
		else if selected == indexPath.item
		{
			selected = nil
		}
		else
		{
			selected = indexPath.item
		}
		tableView.reloadData()
	}
	
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		if let editCell = cell as? ActionEditCell
		{
			editCell.actionName.becomeFirstResponder()
		}
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		if indexPath.item < experience.actions.count
		{
			let action = experience.actions[indexPath.item]
			if self.selected == indexPath.item
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("ActionEditCell") as! ActionEditCell
				cell.action = experience.actions[indexPath.item]
				cell.viewController = self
				return cell;
			}
		
			if action.name == nil
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("ActionURLViewCell") as! ActionURLViewCell
				cell.action = experience.actions[indexPath.item]
				return cell;
			}

			let cell = tableView.dequeueReusableCellWithIdentifier("ActionViewCell") as! ActionViewCell
			cell.action = experience.actions[indexPath.item]
			return cell;
		}
		
		let cell = tableView.dequeueReusableCellWithIdentifier("NavigationMenuViewCell") as! NavigationMenuViewCell
		cell.navigationTitle.text = "Add Action"
		cell.navigationIcon.image = UIImage(named: "ic_add_18pt")
		return cell;
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return experience.actions.count + 1
	}
	
	func deleteSelectedAction()
	{
		if let index = selected
		{
			experience.actions.removeAtIndex(index)
			selected = nil
			tableView.reloadData()
		}
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
