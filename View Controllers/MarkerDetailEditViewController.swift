//
//  ACMarkerViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class MarkerViewController: UITableViewController, UITextFieldDelegate, UIAlertViewDelegate
{
	var settings: MarkerSettings = MarkerSettings()
	
	override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
	{
		NSLog("Selected table cell: %ld", indexPath.row);
		let field = tableView.viewWithTag(indexPath.row)
		field.becomeFirstResponder()
	}
	
	@IBAction func validateCode(sender: AnyObject)
	{
	
	}
	
	func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int)
	{
		switch (buttonIndex)
		{
			case 1:
				navigationController.popViewControllerAnimated(true)
			default:
				NSLog("Delete was cancelled by the user \(buttonIndex)");
		}
	}
	
	@IBAction func deleteItem(sender: AnyObject!)
	{
		let alert = UIAlertView(title: "Confirm Delete", message: "Are you sure you want to delete this marker?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Delete")
		alert.show()
	}
	
	@IBAction func save(sender: AnyObject!)
	{
		
	}
	
//	func validateUrl(url: String) -> Bool
//	{
//		let validURL = NSURL(string: url)
//		if (validURL.scheme && validURL.host)
//		{
//			return true;
//		}
//		return false;
//	}
}