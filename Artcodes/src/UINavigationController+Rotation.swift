//
//  NavigationViewController+Rotation.swift
//  artcodes
//
//  Created by Kevin Glover on 1 Oct 2015.
//  Copyright © 2015 Horizon. All rights reserved.
//

import Foundation

extension UINavigationController
{
	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
	{
		if visibleViewController is UIAlertController
		{
			return super.supportedInterfaceOrientations()
		}
		else if let mask = visibleViewController?.supportedInterfaceOrientations()
		{
			return mask
		}
		return super.supportedInterfaceOrientations()
	}
	
	public override func shouldAutorotate() -> Bool
	{
		return true
	}
}