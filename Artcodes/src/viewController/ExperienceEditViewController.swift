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

class ExperienceEditViewController: GAITrackedViewController, CarbonTabSwipeDelegate
{
	let vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), ExperienceEditAvailabilityViewController(), ExperienceEditActionViewController()]
	var tabSwipe: CarbonTabSwipeNavigation!
	var experience: Experience!
	var edited: Experience!
	var account: Account!
	var accountButton: UIBarButtonItem!
	
	
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
		
		accountButton = UIBarButtonItem(image: UIImage(named: "ic_account_box_18pt"), style: .Plain, target: self, action: "pickAccount")
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
		navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "save"), accountButton]
		
		var names: [String] = []
		for vc in vcs
		{
			names.append(vc.name)
			vc.experience = edited
		}
		
		editing = true
		
		//navigationController?.navigationBar.set
		
		tabSwipe = CarbonTabSwipeNavigation()
		tabSwipe.createWithRootViewController(self, tabNames: names, tintColor: UIColor(rgba: "#295a9e"), delegate: self)
		tabSwipe.setTranslucent(false)
		tabSwipe.setNormalColor(UIColor.whiteColor())
		tabSwipe.setSelectedColor(UIColor.whiteColor())
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
					}
					}, cancelBlock: { (picker) in
					}, origin: accountButton)
			}
		}
	}
	
	func cancel()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	func save()
	{
		experience.json = edited.json
		account.saveExperience(experience)
		
		navigationController?.popViewControllerAnimated(true)		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func tabSwipeNavigation(tabSwipe: CarbonTabSwipeNavigation!, viewControllerAtIndex index: UInt) -> UIViewController!
	{
		return vcs[Int(index)]
	}
}
