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
import artcodesScanner
import Alamofire
import AlamofireImage

class ActionEditCell: UITableViewCell, UITextFieldDelegate
{
	@IBOutlet weak var actionName: UITextField!
	@IBOutlet weak var actionURL: UITextField!
	@IBOutlet weak var actionCode: UITextField!

	var viewController: ExperienceEditActionViewController!
	var action: Action!
	{
		didSet
		{
			actionName.text = action?.name
			actionURL.text = action?.url
			actionCode.text = action?.codes.first
			
			actionName.becomeFirstResponder()
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		if textField == actionName
		{
			actionURL.becomeFirstResponder()
		}
		else if textField == actionURL
		{
			actionCode.becomeFirstResponder()
		}
		else
		{
			textField.endEditing(true)
		}
		return true
	}
	
	@IBAction func deleteAction(sender: AnyObject?)
	{
		viewController.deleteSelectedAction()
	}
	
	func textFieldDidEndEditing(textField: UITextField)
	{
		if textField == actionName
		{
			action.name = actionName.text
		}
		else if textField == actionURL
		{
			if var url = actionURL.text
			{
				if !url.hasPrefix("http://") && !url.hasPrefix("https://")
				{
					url = "http://" + url
				}
				
				action.url = url
			}
		}
		else if textField == actionCode
		{
			if action.codes.count > 0
			{
				action.codes[0] = actionCode.text!
			}
			else
			{
				action.codes.append(actionCode.text!)
			}
		}
	}
	
	func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
	{
		if textField == actionCode
		{
			let characters = NSCharacterSet(charactersInString: "0123456789:")
			
			for uni in string.unicodeScalars
			{
				if !characters.longCharacterIsMember(uni.value)
				{
					return false
				}
			}
			// TODO Validate code
		}
		
		return true
	}
}
