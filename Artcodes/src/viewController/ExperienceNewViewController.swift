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
	var vcs: [ExperienceEditBaseViewController] = [ExperienceEditInfoViewController(), AvailabilityListViewController(), ActionListViewController()]
	let experience = Experience()
	var account: Account!
	let fab = UIButton()

	
	init(account: Account)
	{
		if Feature.isEnabled("pipeline_options")
		{
			self.vcs.append(ExperienceEditPipelineViewController())
		}
		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
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
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_close"), style: .plain, target: self, action: #selector(ExperienceEditViewController.cancel))
		
		navigationController?.toolbar.tintColor = UIColor.black
		navigationController?.toolbar.barTintColor = UIColor.white
		
		fab.translatesAutoresizingMaskIntoConstraints = false
		fab.setImage(UIImage(named: "ic_add"), for: UIControlState())
		fab.backgroundColor = UIColor(hex6: 0x295A9E)
		fab.tintColor = UIColor.white
		fab.layer.shadowRadius = 3
		fab.layer.shadowOpacity = 0.2
		fab.layer.shadowOffset = CGSize(width: 0, height: 2)
		fab.layer.cornerRadius = 28
		fab.isHidden = true
		fab.addTarget(self, action: #selector(ExperienceNewViewController.add), for: .touchUpInside)
		
		view.addSubview(fab)
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: fab, attribute: .right, multiplier: 1, constant: 16))
		
		view.addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: fab, attribute: .bottom, multiplier: 1, constant: 16))
		
		view.addConstraint(NSLayoutConstraint(item: fab, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 56))
		
		view.addConstraint(NSLayoutConstraint(item: fab, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 56))
		
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
	
	func indexUpdated(_ index: Int)
	{
		pageControl.currentPage = index
		
		let nextButton = UIButton(type: .custom)
		nextButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		nextButton.setTitleColor(UIColor.black, for: UIControlState())
		nextButton.tintColor = UIColor.black
		nextButton.setTitle("Next", for: UIControlState())
		nextButton.setImage(UIImage(named: "ic_chevron_right"), for: UIControlState())
		nextButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		nextButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		nextButton.addTarget(self, action: #selector(ExperienceNewViewController.goToNextPage), for: .touchUpInside)
		nextButton.sizeToFit()
		
		let saveButton = UIButton(type: .custom)
		saveButton.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		saveButton.setTitleColor(UIColor.black, for: UIControlState())
		saveButton.tintColor = UIColor.black
		saveButton.setTitle("Save", for: UIControlState())
		saveButton.setImage(UIImage(named: "ic_check_white"), for: UIControlState())
		saveButton.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		saveButton.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		saveButton.imageView?.tintColor = UIColor.black
		saveButton.addTarget(self, action: #selector(ExperienceNewViewController.save), for: .touchUpInside)
		saveButton.sizeToFit()
		
		if index == 0
		{
			setToolbarItems([
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				UIBarButtonItem(customView: nextButton)], animated: false)
		}
		else if index == vcs.count - 1
		{
			setToolbarItems([
				UIBarButtonItem(image: UIImage(named: "ic_chevron_left"), style: .plain, target: self, action: #selector(ExperienceNewViewController.prev)),
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				UIBarButtonItem(customView: saveButton)], animated: false)
		}
		else
		{
			setToolbarItems([
				UIBarButtonItem(image: UIImage(named: "ic_chevron_left"), style: .plain, target: self, action: #selector(ExperienceNewViewController.prev)),
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				pageButton!,
				UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
				UIBarButtonItem(customView: nextButton)], animated: false)
		}
			
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
	
	func add()
	{
		vcs[index].add()
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		for vc in vcs
		{
			if let infoViewController = vc as? ExperienceEditInfoViewController
			{
				// Let InfoViewController call next() for it's keyboard toolbars.
				infoViewController.nextCallback = {() -> () in self.goToNextPage()}
			}
		}
		
		pageControl.currentPage = 0
		pageControl.numberOfPages = vcs.count
		pageControl.pageIndicatorTintColor = UIColor.lightGray
		pageControl.currentPageIndicatorTintColor = UIColor(hex6: 0x295A9E)
		
		setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
		
		navigationController?.toolbar.tintColor = UIColor.black
		//navigationController?.toolbar.barTintColor = UIColor(hex6: 0x324A5E)
		navigationController?.toolbar.isTranslucent = false
		navigationController?.toolbar.clipsToBounds = true
		navigationController?.setToolbarHidden(false, animated: animated)
		if let viewController = viewControllers?.first as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.index(of: viewController)
			{
				indexUpdated(nibIndex)
			}
		}
		
		if let infoVC = self.vcs[0] as? ExperienceEditInfoViewController
		{
			infoVC.toolbarHeight = navigationController?.toolbar.frame.height ?? 0
		}
	}

	override func viewWillDisappear(_ animated: Bool)
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
		_ = navigationController?.popViewController(animated: true)
	}
	
	func save()
	{
		view.endEditing(true)
		
		account.saveExperience(experience)
		
		if var viewControllers = navigationController?.viewControllers
		{
			viewControllers.insert(ExperienceViewController(experience: experience), at: viewControllers.count - 1)
			navigationController?.viewControllers = viewControllers
		}
		
		_ = navigationController?.popViewController(animated: true)
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
			setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.reverse, animated: true, completion: nil)
		}
	}
	
	func goToNextPage()
	{
		if index < vcs.count - 1
		{
			index += 1
			pageControl.currentPage = index
			setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let viewController = vc as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.index(of: viewController)
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
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let viewController = vc as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.index(of: viewController)
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
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
	{
		if let viewController = pageViewController.viewControllers?.first as? ExperienceEditBaseViewController
		{
			if let nibIndex = vcs.index(of: viewController)
			{
				index = nibIndex
			}
		}
	}
}
