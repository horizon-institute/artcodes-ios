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
import UIKit

class ExplanationViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
	var index = 0
	{
		didSet
		{
			if index == nibs.count - 1
			{
				setToolbarItems([
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					pageButton!,
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "skip")], animated: false)
			}
			else if oldValue == nibs.count - 1
			{
				setToolbarItems([
					UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: "skip"),
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					pageButton!,
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					UIBarButtonItem(image: UIImage(named: "ic_chevron_right_18pt"), style: .Plain, target: self, action: "next")], animated: false)
			}
			
			pageControl.currentPage = index
		}
	}
	let nibs = ["Explain1ViewController", "Explain2ViewController", "Explain3ViewController", "Explain4ViewController"]
	let pageControl = UIPageControl()
	var pageButton: UIBarButtonItem?
	
	init()
	{
		super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: [:])
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
		
	}
	
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		pageControl.currentPage = 0
		pageControl.numberOfPages = nibs.count
		//pageControl.addTarget(self, action: "openPage", forControlEvents: .ValueChanged)

		setViewControllers([viewControllerAtIndex(index)], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
		
		//navigationController?.setNavigationBarHidden(true, animated: animated)
		navigationController?.toolbar.tintColor = UIColor.whiteColor()
		navigationController?.toolbar.barTintColor = UIColor(rgba: "#324A5E")
		navigationController?.toolbar.translucent = false
		navigationController?.setToolbarHidden(false, animated: animated)
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationItem.hidesBackButton = true
		navigationItem.title = "What is an Artcode?"
		setToolbarItems([
			UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: "skip"),
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
			pageButton!,
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
			UIBarButtonItem(image: UIImage(named: "ic_chevron_right_18pt"), style: .Plain, target: self, action: "next")], animated: true)
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewDidDisappear(animated)
		navigationController?.navigationBar.shadowImage = nil
		navigationController?.setNavigationBarHidden(false, animated: animated)
		navigationController?.setToolbarHidden(true, animated: animated)
	}
	
	func skip()
	{
		navigationController?.popViewControllerAnimated(false)
	}
	
	func next()
	{
		if index < nibs.count - 1
		{
			index++
			pageControl.currentPage = index
			setViewControllers([viewControllerAtIndex(index)], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
		}
	}
	
	func viewControllerAtIndex(index: Int) -> UIViewController!
	{
		if index < 0 || index >= nibs.count
		{
			return nil
		}
		
		let nib = nibs[index]
		if let placeView = NSBundle.mainBundle().loadNibNamed(nib, owner: self, options: nil).first as? UIViewController
		{
			placeView.restorationIdentifier = nib
			return placeView
		}
		
		return nil
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let nibName = viewController.restorationIdentifier
		{
			if let nibIndex = nibs.indexOf(nibName)
			{
				currentIndex = nibIndex
			}
		}
		
		if currentIndex == nibs.count - 1
		{
			return nil
		}
		
		return viewControllerAtIndex(currentIndex + 1)
		
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let nibName = viewController.restorationIdentifier
		{
			if let nibIndex = nibs.indexOf(nibName)
			{
				currentIndex = nibIndex
			}
		}
		
		if currentIndex == 0
		{
			return nil
		}
		
		return viewControllerAtIndex(currentIndex - 1)
	}	
	
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
	{
		if let nibName = pageViewController.viewControllers?.first?.restorationIdentifier
		{
			if let nibIndex = nibs.indexOf(nibName)
			{
				index = nibIndex
			}
		}
	}
}