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

class ExperienceNewViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
	var index = 0
	{
		didSet
		{
			pageControl.currentPage = index
			indexUpdated(index)
		}
	}
	let pageControl = UIPageControl()
	var pageButton: UIBarButtonItem?
	let vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), AvailabilityListViewController(), ActionListViewController()]
	let experience = Experience()
	var account: Account!
	let fab = UIButton()

	
	init(account: Account)
	{
		super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: [:])
		self.account = account
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		dataSource = self
		delegate = self
		
		pageButton = UIBarButtonItem(customView: pageControl)
		
        //screenName = "New Experience"
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .Plain, target: self, action: #selector(ExperienceEditViewController.cancel))
		
		navigationController?.toolbar.tintColor = UIColor.blackColor()
		navigationController?.toolbar.barTintColor = UIColor.whiteColor()
		
		fab.translatesAutoresizingMaskIntoConstraints = false
		fab.setImage(UIImage(named: "ic_add"), forState: .Normal)
		fab.backgroundColor = UIColor(hex6: 0x295A9E)
		fab.tintColor = UIColor.whiteColor()
		fab.layer.shadowRadius = 3
		fab.layer.shadowOpacity = 0.2
		fab.layer.shadowOffset = CGSize(width: 0, height: 2)
		fab.layer.cornerRadius = 28
		fab.hidden = true
		fab.addTarget(self, action: #selector(ExperienceNewViewController.add), forControlEvents: .TouchUpInside)
		
		view.addSubview(fab)
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: fab, attribute: .Right, multiplier: 1, constant: 16))
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: fab, attribute: .Bottom, multiplier: 1, constant: 16))
		
		view.addConstraint(NSLayoutConstraint(item: fab, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 56))
		
		view.addConstraint(NSLayoutConstraint(item: fab, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 56))
		
		var names: [String] = []
		for vc in vcs
		{
			names.append(vc.name)
			vc.experience = experience
		}
		
//		if experience.id == nil
//		{
//			toolbar.hidden = true
//			let heightConstraint = NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 0)
//			toolbar.addConstraint(heightConstraint)
//		}
	}
	
	func indexUpdated(index: Int)
	{
		pageControl.currentPage = index
		
		let nextButton = UIButton(type: .Custom)
		//nextButton.frame = CGRectMake(0, 0, 100, 50)
		nextButton.titleLabel?.font = UIFont.systemFontOfSize(13)
		nextButton.transform = CGAffineTransformMakeScale(-1.0, 1.0)
		nextButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
		nextButton.tintColor = UIColor.blackColor()
		nextButton.setTitle("NEXT", forState: .Normal)
		nextButton.setImage(UIImage(named: "ic_chevron_right"), forState: .Normal)
		nextButton.titleLabel?.transform = CGAffineTransformMakeScale(-1.0, 1.0)
		nextButton.imageView?.transform = CGAffineTransformMakeScale(-1.0, 1.0)
		nextButton.addTarget(self, action: #selector(ExperienceNewViewController.next), forControlEvents: .TouchUpInside)
		nextButton.sizeToFit()
		
		if index == 0
		{
			setToolbarItems([
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				UIBarButtonItem(customView: nextButton)], animated: false)
		}
		else if index == vcs.count - 1
		{
			setToolbarItems([
				UIBarButtonItem(image: UIImage(named: "ic_chevron_left"), style: .Plain, target: self, action: #selector(ExperienceNewViewController.prev)),
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				UIBarButtonItem(title: "SAVE", style: .Plain, target: self, action: #selector(ExperienceNewViewController.save))], animated: false)
		}
		else
		{
			setToolbarItems([
				UIBarButtonItem(image: UIImage(named: "ic_chevron_left"), style: .Plain, target: self, action: #selector(ExperienceNewViewController.prev)),
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
				UIBarButtonItem(customView: nextButton)], animated: false)
		}
			
		let hide = !vcs[Int(index)].addEnabled
		if hide != fab.hidden
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
	
	func add()
	{
		vcs[index].add()
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		for vc in vcs
		{
			if let infoViewController = vc as? ExperienceEditInfoViewController
			{
				// Let InfoViewController call next() for it's keyboard toolbars.
				infoViewController.nextCallback = {() -> () in self.next()}
			}
		}
		
		pageControl.currentPage = 0
		pageControl.numberOfPages = vcs.count
		pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
		pageControl.currentPageIndicatorTintColor = UIColor(hex6: 0x295A9E)
		
		setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
		
		navigationController?.toolbar.tintColor = UIColor.blackColor()
		//navigationController?.toolbar.barTintColor = UIColor(hex6: 0x324A5E)
		navigationController?.toolbar.translucent = false
		navigationController?.toolbar.clipsToBounds = true
		navigationController?.setToolbarHidden(false, animated: animated)
		if let viewController = viewControllers?.first as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.indexOf(viewController)
			{
				indexUpdated(nibIndex)
			}
		}
	}

	override func viewWillDisappear(animated: Bool)
	{
		super.viewDidDisappear(animated)
		navigationController?.setToolbarHidden(true, animated: animated)
		
		
		for vc in vcs
		{
			if let infoViewController = vc as? ExperienceEditInfoViewController
			{
				// Remove the callback from InfoViewController
				infoViewController.nextCallback = {() -> () in return}
			}
		}
	}
	
	func cancel()
	{
		navigationController?.popViewControllerAnimated(true)
	}
	
	func save()
	{
		view.endEditing(true)
		
		account.saveExperience(experience)
		
		if var viewControllers = navigationController?.viewControllers
		{
			viewControllers.insert(ExperienceViewController(experience: experience), atIndex: viewControllers.count - 1)
			navigationController?.viewControllers = viewControllers
		}
		
		navigationController?.popViewControllerAnimated(true)		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
	
	func prev()
	{
		if index > 0
		{
			index -= 1
			pageControl.currentPage = index
			setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
		}
	}
	
	func next()
	{
		if index < vcs.count - 1
		{
			index += 1
			pageControl.currentPage = index
			setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
		}
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController vc: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let viewController = vc as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.indexOf(viewController)
			{
				currentIndex = nibIndex
			}
		}
		
		if currentIndex == vcs.count - 1
		{
			return nil
		}
		
		return vcs[currentIndex + 1]
		
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController vc: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let viewController = vc as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.indexOf(viewController)
			{
				currentIndex = nibIndex
			}
		}
		
		if currentIndex == 0
		{
			return nil
		}
		
		return vcs[currentIndex - 1]
	}
	
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
	{
		if let viewController = pageViewController.viewControllers?.first as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.indexOf(viewController)
			{
				index = nibIndex
			}
		}
	}
}
