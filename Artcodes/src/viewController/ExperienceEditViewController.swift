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
import CarbonKit
import ActionSheetPicker_3_0

class ExperienceEditViewController: GAITrackedViewController, CarbonTabSwipeNavigationDelegate
{
	let vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), ExperienceEditAvailabilityViewController(), ExperienceEditActionViewController()]
	var tabSwipe: CarbonTabSwipeNavigation!
	var experience: Experience!
	var edited: Experience!
	var account: Account!
	var accountButton: UIBarButtonItem!
	var toolbar: UIToolbar!
	
	
	init(experience: Experience, account: Account)
	{
		super.init(nibName: nil, bundle: nil)
		self.experience = experience
		self.account = account
	}

	required init?(coder aDecoder: NSCoder)
	{
	    super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
        
        screenName = "Edit Experience"

		edited = Experience(json: experience.json)
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "save")
		
		var names: [String] = []
		for vc in vcs
		{
			names.append(vc.name)
			vc.experience = edited
		}
		
		editing = true
		
		tabSwipe = CarbonTabSwipeNavigation(items: names, delegate: self)
		tabSwipe.insertIntoRootViewController(self)
		tabSwipe.setNormalColor(UIColor(rgba: "#295a9e"))
		tabSwipe.setSelectedColor(UIColor(rgba: "#295a9e"))
		tabSwipe.setIndicatorColor(UIColor(rgba: "#295a9e"))
		tabSwipe.setTabExtraWidth(50)
		//tabSwipe.toolbar.backgroundColor = UIColor(rgba: "#295a9e")
		
		var frame = CGRect()
		var remain = CGRect()
		CGRectDivide(view.bounds, &frame, &remain, 44, CGRectEdge.MaxYEdge);
		toolbar = UIToolbar(frame: frame)
		toolbar.tintColor = UIColor(rgba: "#324A5E")
		toolbar.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
		view.addSubview(toolbar)

		accountButton = UIBarButtonItem(title: account.name, style: .Plain, target: self, action: "pickAccount")
		let deleteItem = UIBarButtonItem(image: UIImage(named:"ic_delete_18pt"), style: .Plain, target: self, action: "deleteExperience")
		let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)

		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			if appDelegate.server.accounts.count == 1
			{
				toolbar.items = [deleteItem]
			}
			else
			{
				toolbar.items = [deleteItem, flex, accountButton]
			}
		}
		else
		{
			toolbar.items = [deleteItem, flex, accountButton]
		}
		
		updateAccount()
	}
	
	func updateAccount()
	{
		accountButton.title = "Save \(account.location)"
		toolbar.layoutIfNeeded()
	}
	
	func pickAccount()
	{
		if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
		{
			var accounts: [String] = []
			let accountIDs =  appDelegate.server.accounts.keys.sort()
			for id in accountIDs
			{
				if let account = appDelegate.server.accounts[id]
				{
					accounts.append(account.name)
				}
			}
			
			if let index = accountIDs.indexOf(account.id)
			{
				ActionSheetStringPicker.showPickerWithTitle("Select Account", rows: accounts, initialSelection: index, doneBlock: { (picker, index, value) in
					if let account = appDelegate.server.accounts[accountIDs[index]]
					{
						self.account = account
						self.updateAccount()
					}
					}, cancelBlock: { (picker) in
					}, origin: accountButton)
			}
		}
	}
	
	func deleteExperience()
	{
		let refreshAlert = UIAlertController(title: "Delete?", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.Alert)
		
		refreshAlert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction!) in
			if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
			{
				appDelegate.server.deleteExperience(self.experience)
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
		}))
		
		refreshAlert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: nil))
		presentViewController(refreshAlert, animated: true, completion: nil)
	}
	
	func cancel()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	func save()
	{
		view.endEditing(true)
		
		experience.json = edited.json
		account.saveExperience(experience)
		
		if var viewControllers = navigationController?.viewControllers
		{
			if !(viewControllers[ viewControllers.count - 2 ] is ExperienceViewController)
			{
				viewControllers.insert(ExperienceViewController(experience: experience), atIndex: viewControllers.count - 1)
				navigationController?.viewControllers = viewControllers
			}
		}
		
		navigationController?.popViewControllerAnimated(true)		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func carbonTabSwipeNavigation(carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAtIndex index: UInt) -> UIViewController {
		return vcs[Int(index)]
	}
}
