//
//  ACSettingsViewController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UITableViewController, UITextFieldDelegate
{
	@IBOutlet var minRegions: UITextField
	@IBOutlet var maxRegions: UITextField
	@IBOutlet var maxRegionValue: UITextField
	@IBOutlet var maxEmptyRegions: UITextField

	@IBOutlet var validationRegions: UITextField
	@IBOutlet var validationRegionValue: UITextField
	@IBOutlet var checksum: UITextField
	
	override func viewDidLoad()
	{
		loadValues()
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
		}
	}
	
	func loadValues()
	{
		NSLog("\(markerSettings.minRegions)")
		minRegions.text = "\(markerSettings.minRegions)"
		maxRegions.text = "\(markerSettings.maxRegions)"
		maxRegionValue.text = "\(markerSettings.maxRegionValue)"
		maxEmptyRegions.text = "\(markerSettings.maxEmptyRegions)"
		
		validationRegions.text = "\(markerSettings.validationRegions)"
		validationRegionValue.text = "\(markerSettings.validationRegionValue)"
		
		checksum.text = "\(markerSettings.checksumModulo)"
	}
	
	override func viewWillDisappear(animated: Bool)
	{
		super.viewWillDisappear(animated)
		saveValues()
	}
	
	@IBAction func validate(sender : UITextField)
	{
		let value = sender.text.toInt()
		if(!value || value > 20)
		{
			sender.rightView = UIImageView(image: UIImage(named: "error.png"))
			sender.rightViewMode = UITextFieldViewMode.Always
		}
		else
		{
			sender.rightViewMode = UITextFieldViewMode.Never
		}
	}
	
	func saveValues()
	{
		markerSettings.minRegions = minRegions.text.toInt()!
		markerSettings.maxRegions = maxRegions.text.toInt()!
		markerSettings.maxRegionValue = maxRegionValue.text.toInt()!
		markerSettings.maxEmptyRegions = maxEmptyRegions.text.toInt()!
		
		markerSettings.validationRegions = validationRegions.text.toInt()!
		markerSettings.validationRegionValue = validationRegionValue.text.toInt()!
	
		markerSettings.checksumModulo = checksum.text.toInt()!
	}
}