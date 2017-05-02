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
	var vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), AvailabilityListViewController(), ActionListViewController()]
	var tabSwipe: CarbonTabSwipeNavigation!
	var experience: Experience!
	var edited: Experience!
	var account: Account!
	
	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var toolbar: UIToolbar!
	@IBOutlet weak var fab: UIButton!

	init(experience: Experience, account: Account)
	{
		if Feature.isEnabled("pipeline_options")
		{
			self.vcs.append(ExperienceEditPipelineViewController())
		}
		super.init(nibName:"ExperienceEditViewController", bundle: nil)
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
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .plain, target: self, action: #selector(ExperienceEditViewController.cancel))
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(ExperienceEditViewController.save))
		
		var names: [String] = []
		for vc in vcs
		{
			names.append(vc.name)
			vc.experience = edited
		}
		
		if experience.id == nil
		{
			toolbar.isHidden = true
			let heightConstraint = NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 0)
			toolbar.addConstraint(heightConstraint)
		}
		
		tabSwipe = CarbonTabSwipeNavigation(items: names, delegate: self)
		tabSwipe.toolbar.isTranslucent = false
		tabSwipe.toolbar.barTintColor = UIColor(hex6: 0x324A5E)
		tabSwipe.insert(intoRootViewController: self, andTargetView: contentView)
		tabSwipe.setNormalColor(UIColor.white)
		tabSwipe.setSelectedColor(UIColor.white)
		tabSwipe.setIndicatorColor(UIColor.white)
		tabSwipe.setTabExtraWidth(20)
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		
		if let infoVC = self.vcs[0] as? ExperienceEditInfoViewController
		{
			infoVC.toolbarHeight = self.toolbar.frame.height
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		navigationController?.navigationBar.shadowImage = nil
		navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
	}
	
	@IBAction func add(_ sender: AnyObject)
	{
		vcs[Int(tabSwipe.currentTabIndex)].add()
	}
	
	@IBAction func deleteExperience(_ sender: AnyObject)
	{
		let refreshAlert = UIAlertController(title: "Delete?", message: "The experience will be lost for good", preferredStyle: UIAlertControllerStyle.alert)
		
		refreshAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction!) in
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				appDelegate.server.deleteExperience(self.experience)
				self.navigationController?.popToRootViewController(animated: true)
			}
		}))
		
		refreshAlert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
		present(refreshAlert, animated: true, completion: nil)
	}
	
	func cancel()
	{
		navigationController?.popViewController(animated: true)
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
				viewControllers.insert(ExperienceViewController(coder: experience), at: viewControllers.count - 1)
				navigationController?.viewControllers = viewControllers
			}
		}
		
		navigationController?.popViewController(animated: true)		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
	
	func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, willMoveAt index: UInt)
	{
		let hide = !vcs[Int(index)].addEnabled
		if hide != fab.isHidden
		{
			if hide
			{
				fab.circleHide(0.1)
			}
			else
			{
				fab.circleReveal(0.1)
			}
		}
	}
	
	func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController
	{
		return vcs[Int(index)]
	}
}
