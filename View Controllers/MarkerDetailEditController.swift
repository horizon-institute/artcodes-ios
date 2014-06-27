//
//  MarkerViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class MarkerDetailEditController: UITableViewController, UITextFieldDelegate, UIAlertViewDelegate
{
	@IBOutlet var doneButton: UIBarButtonItem
	@IBOutlet var table: UITableView
	@IBOutlet var codeView: UITextField
	@IBOutlet var urlView: UITextField
	var addButton: UIBarButtonItem?
	var marker: MarkerDetail?
	
	override func numberOfSectionsInTableView(UITableView) -> Int
	{
		if marker && marker!.editable
		{
			return 2
		}
		return 1
	}
	
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
		codeView.becomeFirstResponder()
	}
	
	@IBAction func cancel(sender: UIBarButtonItem)
	{
		navigationController.popViewControllerAnimated(true)
	}
	
	
	@IBAction func save(sender: UIBarButtonItem)
	{
		if !marker
		{
			marker = MarkerDetail(code: codeView.text)
			markerSettings.markers[marker!.code] = marker
			marker!.action = urlView.text
			markerSettings.changed = true
		}
		else if marker?.editable
		{
			if marker!.code != codeView.text
			{
				markerSettings.changed = true
				markerSettings.markers[marker!.code] = nil
				marker!.code = codeView.text
				markerSettings.markers[marker!.code] = marker
			}
			else if marker!.action != urlView.text
			{
				marker!.action = urlView.text
				markerSettings.changed = true
			}
		}
		
		navigationController.popViewControllerAnimated(true)
	}
	
	func loadValues()
	{
		if(marker)
		{
			codeView.text = marker?.code
			urlView.text = marker?.action
		
			codeView.enabled = marker!.editable
			urlView.enabled = marker!.editable
			
			if !marker!.editable
			{
				let sections = NSIndexSet(index : 1)
				self.navigationItem.setLeftBarButtonItems(nil, animated: false)
				self.navigationItem.setRightBarButtonItems(nil, animated: false)
			}
			
		}
		else
		{
			addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "save:")
			self.navigationItem.setRightBarButtonItem(addButton, animated: false)
		}
		
		validate(codeView)
	}
	
	@IBAction func validate(sender: AnyObject)
	{
		var valid = true
		if(markerSettings.isValid(string: codeView.text))
		{
			codeView.rightViewMode = UITextFieldViewMode.Never
		}
		else
		{
			codeView.rightView = UIImageView(image: UIImage(named: "error.png"))
			codeView.rightViewMode = UITextFieldViewMode.Always
			valid = false
		}
		
		let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
		
		if urlView.text.rangeOfString(urlRegEx, options: .RegularExpressionSearch)
		{
			urlView.rightViewMode = UITextFieldViewMode.Never
		}
		else
		{
			urlView.rightView = UIImageView(image: UIImage(named: "error.png"))
			urlView.rightViewMode = UITextFieldViewMode.Always
			valid = false
		}
		
		if doneButton
		{
			doneButton.enabled = valid
		}
		
		if addButton
		{
			addButton!.enabled = valid
		}
	}
	
	func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int)
	{
		switch (buttonIndex)
		{
			case 1:
				markerSettings.markers[marker!.code] = nil
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
}