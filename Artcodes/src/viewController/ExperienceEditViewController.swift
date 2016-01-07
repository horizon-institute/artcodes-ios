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

class ExperienceEditViewController: GAITrackedViewController, CarbonTabSwipeNavigationDelegate
{
	let vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), ExperienceEditAvailabilityViewController(), ExperienceEditActionViewController()]
	var tabSwipe: CarbonTabSwipeNavigation!
	var experience: Experience!
	var edited: Experience!
	var account: Account!
	
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
		tabSwipe.toolbar.translucent = false
		tabSwipe.toolbar.barTintColor = UIColor(rgba: "#324A5E")
		tabSwipe.insertIntoRootViewController(self)
		tabSwipe.setNormalColor(UIColor.whiteColor())
		tabSwipe.setSelectedColor(UIColor.whiteColor())
		tabSwipe.setIndicatorColor(UIColor.whiteColor())
		tabSwipe.setTabExtraWidth(50)
		
		if experience.id != nil
		{
			var frame = CGRect()
			var remain = CGRect()
			CGRectDivide(view.bounds, &frame, &remain, 44, CGRectEdge.MaxYEdge);
			let toolbar = UIToolbar(frame: frame)
			toolbar.tintColor = UIColor(rgba: "#324A5E")
			toolbar.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
			view.addSubview(toolbar)

			//accountButton = UIBarButtonItem(title: account.name, style: .Plain, target: self, action: "pickAccount")
			let deleteItem = UIBarButtonItem(image: UIImage(named:"ic_delete_18pt"), style: .Plain, target: self, action: "deleteExperience")
			let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)

			toolbar.items = [flex, deleteItem]
		}
		
		//updateAccount()
	}
	
	override func viewWillAppear(animated: Bool)
	{
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
	}
	
	override func viewDidDisappear(animated: Bool)
	{
		navigationController?.navigationBar.shadowImage = nil
		navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
	}
	
	func deleteExperience()
	{
		let refreshAlert = UIAlertController(title: "Delete?", message: "The experience will be lost for good", preferredStyle: UIAlertControllerStyle.Alert)
		
		refreshAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (action: UIAlertAction!) in
			if let appDelegate = UIApplication.sharedApplication().delegate as? ArtcodeAppDelegate
			{
				appDelegate.server.deleteExperience(self.experience)
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
		}))
		
		refreshAlert.addAction(UIAlertAction(title: "Keep", style: .Cancel, handler: nil))
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
	
	func carbonTabSwipeNavigation(carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAtIndex index: UInt) -> UIViewController
	{
		return vcs[Int(index)]
	}
}
