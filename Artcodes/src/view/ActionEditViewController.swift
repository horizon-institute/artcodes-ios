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

import UIKit
import ArtcodesScanner
import Alamofire
import AlamofireImage

class ActionEditViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource
{
	let codeChars = NSCharacterSet(charactersInString: "0123456789:")
	
	@IBOutlet weak var actionName: UITextField!
	@IBOutlet weak var actionURL: UITextField!
	@IBOutlet weak var matchTypeField: UITextField!
	@IBOutlet weak var codesView: UIView!
	@IBOutlet weak var newCode: UITextField!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var permissionHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var newCodeHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var editableSwitch: UISwitch!
	
	var viewController: ActionListViewController!
	let action: Action
	let index: Int
	
	let codeKeyboardViewController: CodeKeyboardViewController = CodeKeyboardViewController();
	
	var changeNewCodeButtonText = {(x: String) -> () in return}
	
	let toolbar_string_name = "Enter a name for this action"
	let toolbar_string_url = "Enter a URL for this action"
	let toolbar_string_match_mode = "Triggered by matching:"
	let toolbar_string_code = "Enter a code"
	
	let button_string_next = "Next"
	let button_string_done = "Done"
	let button_string_add_new_code = "Add another code"
	
	let match_type_string_any = "any of these codes"
	let match_type_string_all =  "all of these codes"
	let match_type_string_sequence = "these codes in sequence"
	
	init(action: Action, index: Int)
	{
		self.action = action
		self.index = index
		super.init(nibName:"ActionEditViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		action = Action()
		index = 0
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		NSLog("Owner %@", "\(action.owner)")
		
		let editable = (action.owner == nil || action.owner == viewController.experience.id || action.owner == "this")
		
		editableSwitch.on = action.owner == nil
		editableSwitch.enabled = editable
		
		actionName.text = action.name
		actionName.enabled = editable
		actionURL.text = action.displayURL
		actionURL.enabled = editable
		if !editable
		{
			newCodeHeightConstraint.priority = 1000
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActionEditViewController.keyboardShown(_:)), name:UIKeyboardWillShowNotification, object: nil);
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ActionEditViewController.keyboardHidden(_:)), name:UIKeyboardWillHideNotification, object: nil);
		
		actionName.becomeFirstResponder()
		
		self.updateMatchField()
		if editable && Feature.isEnabled("feature_combined_codes")
		{
			let pickerView = UIPickerView()
			pickerView.dataSource = self
			pickerView.delegate = self
			pickerView.selectRow(intForMatchType(action.match), inComponent: 0, animated: false);
			self.matchTypeField.inputView = pickerView;
			self.matchTypeField.enabled = true
		}
		else
		{
			self.matchTypeField.enabled = false
		}
		
		self.actionName.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_name, buttonText: self.button_string_next).tooblar
		self.actionURL.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_url, buttonText: self.button_string_next).tooblar
		self.matchTypeField.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_match_mode, buttonText: self.button_string_next).tooblar
		let newCodeToolbar = self.createKeyboardToolBar(self, selector: #selector(newCodeNextButtonPressed), helpText: self.toolbar_string_code, buttonText: self.button_string_done)
		self.newCode.inputAccessoryView = newCodeToolbar.tooblar
		self.changeNewCodeButtonText = newCodeToolbar.changeButtonTitle
	}
	
	func newCodeNextButtonPressed()
	{
		
		if newCode.text == "" || newCode.text == nil
		{
			newCode.resignFirstResponder()
		}
		else
		{
			removeTrailingColon(newCode)
			action.codes.append(newCode.text!)
			createCodes(true)
			newCode.text = ""
			newCode.becomeFirstResponder()
			self.changeNewCodeButtonText(self.button_string_done)
		}
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		let editable = (action.owner == nil || action.owner == viewController.experience.id || action.owner == "this")
		createCodes(editable)
		
		
		self.codeKeyboardViewController.textFieldToWorkOn = newCode;
		newCode.inputView = self.codeKeyboardViewController.view;
	}
	
	func keyboardShown(notification: NSNotification)
	{
		if let userInfo = notification.userInfo
		{
			if let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue
			{
				let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.CGRectValue().height+100, right: 0)
				scrollView.contentInset = insets
				scrollView.scrollIndicatorInsets = insets
			}
		}
	}
	
	@IBAction func addCode(sender: AnyObject)
	{
		let vc = AddCodeViewController(action: action)
		self.presentViewController(vc, animated: true, completion: nil)
	}
	
	func keyboardHidden(notification:NSNotification)
	{
		scrollView.contentInset = UIEdgeInsetsZero;
		scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
	}
	
	@IBAction func pickerToolbarNextPressed(sender: AnyObject) {
		textFieldShouldReturn(self.matchTypeField)
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		NSLog("textField: %@", textField)
		if textField == actionName
		{
			actionURL.becomeFirstResponder()
		}
		else if textField == actionURL && Feature.isEnabled("feature_combined_codes")
		{
			matchTypeField.becomeFirstResponder()
		}
		else if textField == actionURL || textField == matchTypeField
		{
			if selectCodeEdit(1)
			{
				return true
			}
			newCode.becomeFirstResponder()
		}
		else if textField == newCode
		{
			textField.endEditing(true)
		}
		else if textField.keyboardType == .NumbersAndPunctuation || textField.inputView == self.codeKeyboardViewController.view
		{
			NSLog("textField.tag: %@", textField.tag)
			if selectCodeEdit(textField.tag + 1)
			{
				return true
			}
			newCode.becomeFirstResponder()
		}
		return true
	}
	
	@IBAction func deleteAction(sender: AnyObject)
	{
		actionName.becomeFirstResponder()
		actionName.resignFirstResponder()
		presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
			self.viewController.deleteAction(self.index)
		})
	}
	
	func textFromField(textField: UITextField) -> String?
	{
		if let text = textField.text
		{
			let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
			if trimmed.characters.count > 0
			{
				return trimmed
			}
		}
		return nil
	}
	
	@IBAction func close(sender: AnyObject)
	{
		actionName.becomeFirstResponder()
		actionName.resignFirstResponder()
		
		if newCode.text != nil && newCode.text != ""
		{
			action.codes.append(newCode.text!)
		}
		
		// remove empty strings
		var index = 0
		while (index < action.codes.count)
		{
			if action.codes[index] == ""
			{
				action.codes.removeAtIndex(index)
			}
			else
			{
				index += 1
			}
		}
		
		if action.match != Match.sequence
		{
			action.codes.sortInPlace()
		}
		
		viewController?.tableView.reloadData()
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	var currentTextField: UITextField? = nil
	func textFieldDidBeginEditing(textField: UITextField) {
		self.currentTextField = textField;
		if textField.inputView == self.codeKeyboardViewController.view
		{
			self.codeKeyboardViewController.textFieldToWorkOn = textField
		}
	}
	
	func textFieldDidEndEditing(textField: UITextField)
	{
		if textField == actionName
		{
			action.name = textFromField(textField)
		}
		else if textField == actionURL
		{
			if var url = textFromField(textField)
			{
				if !url.hasPrefix("http://") && !url.hasPrefix("https://")
				{
					url = "http://" + url
				}
				
				action.url = url
			}
			else
			{
				action.url = nil
			}
		}
		else if textField.keyboardType == .NumbersAndPunctuation || textField.inputView == self.codeKeyboardViewController.view
		{
			removeTrailingColon(textField)
			if action.codes.count > (textField.tag - 1) && textField.tag != 0
			{
				if let code = textField.text
				{
					action.codes[textField.tag - 1] = code
				}
			}
			else if textField == newCode && newCode.text != ""
			{
				action.codes.append(newCode.text!)
				newCode.text = ""
				createCodes(true)
			}
		}
	}
	
	func removeTrailingColon(textField: UITextField)
	{
		print("removing trailing colon from \(textField.text)")
		if !(textField.text?.isEmpty ?? true)
		{
			if textField.text?.substringFromIndex(textField.text!.endIndex.predecessor()) == ":"
			{
				textField.text = textField.text?.substringToIndex(textField.text!.endIndex.predecessor())
				print("removd trailing colon from \(textField.text)")
			}
		}
	}
	
	func createCodes(editable: Bool)
	{
		/*for subview in codesView.subviews
		{
			subview.removeFromSuperview()
		}*/
		var lastView: UIView?
		if !action.codes.isEmpty
		{
			for index in 1...action.codes.count
			{
				let code = action.codes[index - 1]
				
				if let codeView = codesView.viewWithTag(index+20000) as? CodeView
				{
					print("re-assign code view \(codeView.tag)")
					// TODO codeView.availability = availability
					codeView.codeEdit.text = code
					codeView.codeEdit.enabled = editable
					
					codeView.codeEdit.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: "Enter a code", buttonText: self.button_string_add_new_code).tooblar
					
					lastView = codeView
				}
				else
				if let codeView = NSBundle.mainBundle().loadNibNamed("CodeView", owner: self, options: nil)![0] as? CodeView
				{
					print("create code view \(index+20000) lastview=\(lastView)")
					// TODO codeView.availability = availability
					codeView.codeEdit.text = code
					codeView.codeEdit.delegate = self
					codeView.codeEdit.tag = index
					codeView.tag = index + 20000
					codeView.codeEdit.enabled = editable
					codeView.translatesAutoresizingMaskIntoConstraints = false
					
					codeView.codeEdit.inputView = self.codeKeyboardViewController.view
					codeView.codeEdit.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: "Enter a code", buttonText: self.button_string_add_new_code).tooblar
					
					codesView.addSubview(codeView)
					
					if let previousView = lastView
					{
						codesView.addConstraint(NSLayoutConstraint(item: codeView, attribute: .Top,
							relatedBy: .Equal,
							toItem: previousView, attribute: .Bottom,
							multiplier: 1.0,
							constant: 0.0))
					}
					else
					{
						codesView.addConstraint(NSLayoutConstraint(item: codeView, attribute: .Top,
							relatedBy: .Equal,
							toItem: codesView, attribute: .Top,
							multiplier: 1.0,
							constant: 0.0))
					}
					
					codesView.addConstraint(NSLayoutConstraint(item: codeView, attribute: .Left,
						relatedBy: .Equal,
						toItem: codesView, attribute: .Left,
						multiplier: 1.0,
						constant: 0.0))
					codesView.addConstraint(NSLayoutConstraint(item: codeView, attribute: .Right,
						relatedBy: .Equal,
						toItem: codesView, attribute: .Right,
						multiplier: 1.0,
						constant: 0.0))
					
					lastView = codeView
				}
			}
		}
		
		if let previousView = lastView
		{
			codesView.addConstraint(NSLayoutConstraint(item: previousView, attribute: .Bottom,
				relatedBy: .LessThanOrEqual,
				toItem: codesView, attribute: .Bottom,
				multiplier: 1.0,
				constant: 0.0))
		}
	}
	
	func selectCodeEdit(index: Int) -> Bool
	{
		for view in codesView.subviews
		{
			for subview in view.subviews
			{
				if subview is UITextField && subview.tag == index
				{
					subview.becomeFirstResponder()
					return true
				}
			}
		}
		return false
	}
	
	func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
	{
		// ! the causes the scroll prob
		/*if textField == newCode
		{
			for uni in string.unicodeScalars
			{
				if !codeChars.longCharacterIsMember(uni.value)
				{
					return false
				}
			}
			action.codes.append(string)
			createCodes(true)
			selectCodeEdit(action.codes.count)
		}
		else */
		if textField.keyboardType == .NumbersAndPunctuation || textField.inputView == self.codeKeyboardViewController.view
		{
			if let text = textField.text
			{
				let result: NSString = NSString(string: text).stringByReplacingCharactersInRange(range, withString: string)
				// prevent double colons
				if string == ":" && (range.location == 0 || (range.location >= 1 && result.substringWithRange(NSMakeRange(range.location-1, 2)) == "::"))
				{
					return false
				}
				else
				{
					for uni in string.unicodeScalars
					{
						if !codeChars.longCharacterIsMember(uni.value)
						{
							return false
						}
					}
				}
				
				if textField == newCode
				{
					self.changeNewCodeButtonText(result=="" ? self.button_string_done : self.button_string_add_new_code)
				}
			}
		}
		
		return true
	}
	
	@IBAction func editChanged(sender: AnyObject)
	{
		if editableSwitch.on
		{
			action.owner = nil
		}
		else if viewController.experience.id != nil
		{
			action.owner = viewController.experience.id
		}
		else
		{
			action.owner = "this"
		}
		NSLog("Owner %@", "\(action.owner)")
	}
	
	@IBAction func toggleEdit(sender: AnyObject)
	{
		editableSwitch.setOn(!editableSwitch.on, animated: true)
		editChanged(sender)
	}
	
	// UIPickerView functions:
	
	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		return self.stringForMatchType(self.matchTypeForInt(row))
	}
	
	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return 3
	}
	
	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		self.action.match = self.matchTypeForInt(row)
		self.updateMatchField()
	}
	
	// Match type field functions:
	
	func updateMatchField()
	{
		self.matchTypeField.text = self.toolbar_string_match_mode + stringForMatchType(self.action.match)
	}
	
	func matchTypeForInt(n: Int) -> Match {
		switch n {
		case 0:
			return Match.any
		case 1:
			return Match.all
		case 2:
			return Match.sequence
		default:
			return Match.any
		}
	}
	func stringForMatchType(match: Match) -> String
	{
		switch match {
		case Match.any:
			return self.match_type_string_any
		case Match.all:
			return self.match_type_string_all
		case Match.sequence:
			return self.match_type_string_sequence
		}
	}
	func intForMatchType(match: Match) -> Int
	{
		switch match {
		case Match.any:
			return 0
		case Match.all:
			return 1
		case Match.sequence:
			return 2
		}
	}
	
	
	// Keyboard toolbar functions:
	func createKeyboardToolBar(target: AnyObject, selector:Selector, helpText:String, buttonText:String) -> (tooblar: UIToolbar, changeButtonTitle: (String)->()) {
		let toolBar = UIToolbar()
		toolBar.barStyle = UIBarStyle.Default
		toolBar.translucent = true
		let helpButton = UIBarButtonItem(title: helpText, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
		helpButton.tintColor = UIColor.blackColor()
		let nextButton = UIBarButtonItem(title: buttonText, style: UIBarButtonItemStyle.Plain, target: target, action: selector)
		let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
		toolBar.setItems([helpButton, spaceButton, nextButton], animated: false)
		toolBar.userInteractionEnabled = true
		toolBar.sizeToFit()
		
		return (toolBar, {(title: String) -> () in nextButton.title = title })
	}
	func moveToNextTextField()
	{
		if let currentTextField = self.currentTextField
		{
			if (currentTextField == self.actionName && self.actionName.isFirstResponder())
			{
				self.actionURL.becomeFirstResponder()
			}
			else if(currentTextField == self.actionURL && self.actionURL.isFirstResponder() && Feature.isEnabled("feature_combined_codes"))
			{
				self.matchTypeField.becomeFirstResponder()
			}
			else
			{
				self.newCode.becomeFirstResponder()
			}
		}
	}
}
