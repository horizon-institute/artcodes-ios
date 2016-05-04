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

class ActionEditViewController: UIViewController, UITextFieldDelegate
{
	let codeChars = NSCharacterSet(charactersInString: "0123456789:")
	
	@IBOutlet weak var actionName: UITextField!
	@IBOutlet weak var actionURL: UITextField!
	@IBOutlet weak var codesView: UIView!
	@IBOutlet weak var newCode: UITextField!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var permissionHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var newCodeHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var editableSwitch: UISwitch!
	
	var viewController: ActionListViewController!
	let action: Action
	let index: Int
	
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
		
		NSLog("Owner \(action.owner)")
		
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
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		let editable = (action.owner == nil || action.owner == viewController.experience.id || action.owner == "this")
		createCodes(editable)
	}
	
	func keyboardShown(notification: NSNotification)
	{
		if let userInfo = notification.userInfo
		{
			if let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue
			{
				let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.CGRectValue().height, right: 0)
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
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		NSLog("\(textField)")
		if textField == actionName
		{
			actionURL.becomeFirstResponder()
		}
		else if textField == actionURL
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
		else if textField.keyboardType == .NumbersAndPunctuation
		{
			NSLog("\(textField.tag)")
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
		viewController?.tableView.reloadData()
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
		else if textField.keyboardType == .NumbersAndPunctuation
		{
			if action.codes.count > (textField.tag - 1) && textField.tag != 0
			{
				if let code = textField.text
				{
					action.codes[textField.tag - 1] = code
				}
			}
		}
	}
	
	func createCodes(editable: Bool)
	{
		for subview in codesView.subviews
		{
			subview.removeFromSuperview()
		}
		var lastView: UIView?
		if !action.codes.isEmpty
		{
			for index in 1...action.codes.count
			{
				let code = action.codes[index - 1]
				if let codeView = NSBundle.mainBundle().loadNibNamed("CodeView", owner: self, options: nil)[0] as? CodeView
				{
					// TODO codeView.availability = availability
					codeView.codeEdit.text = code
					codeView.codeEdit.delegate = self
					codeView.codeEdit.tag = index
					codeView.codeEdit.enabled = editable
					codeView.translatesAutoresizingMaskIntoConstraints = false
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
				relatedBy: .Equal,
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
		if textField == newCode
		{
			for uni in string.unicodeScalars
			{
				if !codeChars.longCharacterIsMember(uni.value)
				{
					return false
				}
			}
			action.codes.append("")
			createCodes(true)
			selectCodeEdit(action.codes.count)
		}
		else if textField.keyboardType == .NumbersAndPunctuation
		{
			if let text = textField.text
			{
				let result = NSString(string: text).stringByReplacingCharactersInRange(range, withString: string)
				if result.isEmpty
				{
					newCode.becomeFirstResponder()
					action.codes.removeAtIndex(textField.tag - 1)
					createCodes(true)
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
		NSLog("Owner \(action.owner)")
	}
	
	@IBAction func toggleEdit(sender: AnyObject)
	{
		editableSwitch.setOn(!editableSwitch.on, animated: true)
		editChanged(sender)
	}
}
