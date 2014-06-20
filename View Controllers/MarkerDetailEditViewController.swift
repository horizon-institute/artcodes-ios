//
//  MarkerViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class MarkerViewController: UITableViewController, UITextFieldDelegate, UIAlertViewDelegate
{
	@IBOutlet var codeView: UITextField
	@IBOutlet var urlView: UITextField
	var marker: MarkerDetail?
	var save = true
	
	override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
	{
		let cell = tableView.cellForRowAtIndexPath(indexPath)
		let view = cell.contentView
		for subview : AnyObject in view.subviews
		{
			if subview is UITextField
			{
				subview.becomeFirstResponder()
			}
			else if subview is UIButton
			{
				subview.sendActionsForControlEvents(.TouchUpInside)
			}
		}
	}
	
	override func viewDidLoad() 
	{
		loadValues()
		save = true
		codeView.becomeFirstResponder()
	}
	
	func loadValues()
	{
		codeView.text = marker?.code
		urlView.text = marker?.action
		
		codeView.enabled = marker!.editable
		urlView.enabled = marker!.editable
				
		validateCode(codeView)
		validateUrl(urlView)
	}
	
	@IBAction func validateCode(sender: UITextField)
	{
		if(markerSettings.isValid(string: sender.text))
		{
			NSLog("\(sender.text) is valid")
			sender.rightViewMode = UITextFieldViewMode.Never
		}
		else
		{
			NSLog("\(sender.text) is not valid")
			sender.rightView = UIImageView(image: UIImage(named: "error.png"))
			sender.rightViewMode = UITextFieldViewMode.Always
		}
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		NSLog("Saving marker")
		
		if(save && marker?.editable)
		{
			marker!.action = urlView.text
			if(marker!.code != codeView.text)
			{
				markerSettings.markers[marker!.code] = nil
				marker!.code = codeView.text
				markerSettings.markers[marker!.code] = marker
			}
		}
	}
	
	func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int)
	{
		switch (buttonIndex)
		{
			case 1:
				markerSettings.markers[marker!.code] = nil
				save = false
				navigationController.popViewControllerAnimated(true)
			default:
				NSLog("Delete was cancelled by the user \(buttonIndex)");
		}
	}
	
	@IBAction func deleteItem(sender: AnyObject!)
	{
		let alert = UIAlertView()
		alert.title = "Confirm Delete"
		alert.message = "Are you sure you want to delete this marker?"
		alert.delegate = self
		alert.addButtonWithTitle("Cancel")
		alert.addButtonWithTitle("Delete")
		alert.show()
	}
		
	@IBAction func validateUrl(sender : UITextField)
	{
		//		let validURL = NSURL(string: url)
		//		if (validURL.scheme && validURL.host)
		//		{
		//			return true;
		//		}
		//		return false;
	}
}