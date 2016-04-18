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

class AboutArtcodesViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate
{
	var index = 0
	{
		didSet
		{
			if index == vcs.count - 1
			{
				setToolbarItems([
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					pageButton!,
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(AboutArtcodesViewController.skip))], animated: false)
			}
			else if oldValue == vcs.count - 1
			{
				setToolbarItems([
					UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: #selector(AboutArtcodesViewController.skip)),
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					pageButton!,
					UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
					UIBarButtonItem(image: UIImage(named: "ic_chevron_right_18pt"), style: .Plain, target: self, action: #selector(AboutArtcodesViewController.next))], animated: false)
			}
			pageControl.currentPage = index
		}
	}
	let vcs = [UIViewController(nibName: "AboutArtcodes1ViewController", bundle: nil), UIViewController(nibName: "AboutArtcodes2ViewController", bundle: nil), UIViewController(nibName: "AboutArtcodes3ViewController", bundle: nil)]
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
		pageControl.numberOfPages = vcs.count

		setViewControllers([vcs[index]], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
		
		navigationController?.toolbar.tintColor = UIColor.whiteColor()
		navigationController?.toolbar.barTintColor = UIColor(hex6: 0x324A5E)
		navigationController?.toolbar.translucent = false
		navigationController?.toolbar.clipsToBounds = true
		navigationController?.setNavigationBarHidden(true, animated: animated)
		navigationController?.setToolbarHidden(false, animated: animated)
		setToolbarItems([
			UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: #selector(AboutArtcodesViewController.skip)),
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
			pageButton!,
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
			UIBarButtonItem(image: UIImage(named: "ic_chevron_right_18pt"), style: .Plain, target: self, action: #selector(AboutArtcodesViewController.next))], animated: true)
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewDidDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
		navigationController?.setToolbarHidden(true, animated: animated)
	}
	
	func skip()
	{
		Feature.enable("feature_hide_welcome")
		navigationController?.popViewControllerAnimated(true)
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
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let nibIndex = vcs.indexOf(viewController)
		{
			currentIndex = nibIndex
		}
		
		if currentIndex == vcs.count - 1
		{
			return nil
		}
		
		NSLog("Next \(currentIndex + 1)")
		
		return vcs[currentIndex + 1]
		
	}
	
	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
	{
		var currentIndex = index
		if let nibIndex = vcs.indexOf(viewController)
		{
			currentIndex = nibIndex
		}
		
		if currentIndex == 0
		{
			return nil
		}
		
		NSLog("Prev: \(currentIndex - 1)")
		
		return vcs[currentIndex - 1]
	}	
	
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
	{
		if let nibIndex = vcs.indexOf((pageViewController.viewControllers?.first)!)
		{
				index = nibIndex
		}
	}
}