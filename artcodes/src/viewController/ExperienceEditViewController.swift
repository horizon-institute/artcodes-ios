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
