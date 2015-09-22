//
//  ExperienceEditInfoViewController.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import Foundation
import artcodesScanner
import CarbonKit

class ExperienceEditViewController: ArtcodeViewController, CarbonTabSwipeDelegate
{
	let vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController()]//, ExperienceEditAvailabilityViewController(), ExperienceEditActionViewController()]
	var tabSwipe: CarbonTabSwipeNavigation!
	var experience: Experience!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
        
        screenName = "Edit Experience"

		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "save")
		
		var names: [String] = []
		for vc in vcs
		{
			names.append(vc.name)
			vc.experience = experience
		}
		
		editing = true
		
		//navigationController?.navigationBar.set
		
		tabSwipe = CarbonTabSwipeNavigation()
		tabSwipe.createWithRootViewController(self, tabNames: names, tintColor: UIColor(rgba: "#295a9e"), delegate: self)
		tabSwipe.setTranslucent(false)
		tabSwipe.setNormalColor(UIColor.whiteColor())
		tabSwipe.setSelectedColor(UIColor.whiteColor())
	}
	
	func cancel()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	func save()
	{
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
