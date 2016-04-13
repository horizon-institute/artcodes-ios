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

class ActionListViewController: ExperienceEditBaseViewController, UITableViewDataSource, UITableViewDelegate
{
	@IBOutlet weak var tableView: UITableView!
	
	override var name: String
	{
		return "Actions"
	}
	
	override var addEnabled: Bool
	{
		return true
	}

	init()
	{
		super.init(nibName:"ActionListViewController", bundle:nil)
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
		
		let urlNib = UINib(nibName: "ActionURLViewCell", bundle:nil)
		tableView.registerNib(urlNib, forCellReuseIdentifier: "ActionURLViewCell")
		
		modalPresentationStyle = .FormSheet
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		let action = experience.actions[indexPath.item]
		let vc = ActionEditViewController(action: action, index: indexPath.item)
		vc.viewController = self
		self.presentViewController(vc, animated: true, completion: nil)
	}

	override func add()
	{
		let action = Action()
		experience.actions.append(action)
		tableView.reloadData()
		let vc = ActionEditViewController(action: action, index: experience.actions.count - 1)
		vc.viewController = self
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
	func deleteAction(index: Int)
	{
		let action = experience.actions[index]
		experience.actions.removeAtIndex(index)
		tableView.reloadData()
		
		let snackbar = TTGSnackbar.init(message: "Deleted Action", duration: TTGSnackbarDuration.Middle, actionText: "Undo")
		{ (snackbar) -> Void in
			self.experience.actions.insert(action, atIndex: index)
			self.tableView.reloadData()
		}
		snackbar.show()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		if indexPath.item < experience.actions.count
		{
			let action = experience.actions[indexPath.item]
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
		
		return UITableViewCell()
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return experience.actions.count
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
