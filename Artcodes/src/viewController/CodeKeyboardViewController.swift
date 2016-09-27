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
import AudioToolbox

class CodeKeyboardViewController: UIViewController
{
	var textFieldToWorkOn: UITextField? = nil;
	
	init()
	{
		super.init(nibName: "CodeKeyboard", bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
	}
	
	func insertCharacter(c:String)
	{
		if let nonNilTextField = self.textFieldToWorkOn
		{
			if let delegate = nonNilTextField.delegate
			{
				let beginning: UITextPosition = nonNilTextField.beginningOfDocument
				
				let selectedRange: UITextRange = nonNilTextField.selectedTextRange!
				let selectionStart: UITextPosition = selectedRange.start
				let selectionEnd: UITextPosition = selectedRange.end
				
				let location: NSInteger = nonNilTextField.offsetFromPosition(beginning, toPosition:selectionStart)
				let length:   NSInteger = nonNilTextField.offsetFromPosition(selectionStart, toPosition:selectionEnd)
				
				let range = NSMakeRange(location, length)
				
				if (delegate.textField!(nonNilTextField, shouldChangeCharactersInRange: range, replacementString: c))
				{
					nonNilTextField.insertText(c)
				}
			}
			else
			{
				nonNilTextField.insertText(c)
			}
		}
	}
	
	
	func removeCharacter()
	{
		if let nonNilTextField = self.textFieldToWorkOn
		{
			if let delegate = nonNilTextField.delegate
			{
				let beginning: UITextPosition = nonNilTextField.beginningOfDocument
				
				let selectedRange: UITextRange = nonNilTextField.selectedTextRange!
				let selectionStart: UITextPosition = selectedRange.start
				let selectionEnd: UITextPosition = selectedRange.end
				
				let location: NSInteger = nonNilTextField.offsetFromPosition(beginning, toPosition:selectionStart)
				let length:   NSInteger = nonNilTextField.offsetFromPosition(selectionStart, toPosition:selectionEnd)
				
				var range: NSRange
				if (length==0 && location==0)
				{
					return
				}
				else if (length==0)
				{
					// delete single character at cursor
					range = NSMakeRange(location-1, 1)
				}
				else
				{
					// delete selected text
					range = NSMakeRange(location, length)
				}
				
				if (delegate.textField!(nonNilTextField, shouldChangeCharactersInRange: range, replacementString: ""))
				{
					nonNilTextField.deleteBackward()
				}
			}
			else
			{
				nonNilTextField.deleteBackward()
			}
		}
	}
	
	@IBAction func button1Pressed(sender: AnyObject) {playSound(); insertCharacter("1")}
	@IBAction func button2Pressed(sender: AnyObject) {playSound(); insertCharacter("2")}
	@IBAction func button3Pressed(sender: AnyObject) {playSound(); insertCharacter("3")}
	@IBAction func buttonBSPressed(sender: AnyObject) {playSound(); removeCharacter()}
	
	@IBAction func button4Pressed(sender: AnyObject) {playSound(); insertCharacter("4")}
	@IBAction func button5Pressed(sender: AnyObject) {playSound(); insertCharacter("5")}
	@IBAction func button6Pressed(sender: AnyObject) {playSound(); insertCharacter("6")}
	@IBAction func buttonRegionSeperatorPressed(sender: AnyObject) {playSound(); insertCharacter(":")}
	
	@IBAction func button7Pressed(sender: AnyObject) {playSound(); insertCharacter("7")}
	@IBAction func button8Pressed(sender: AnyObject) {playSound(); insertCharacter("8")}
	@IBAction func button9Pressed(sender: AnyObject) {playSound(); insertCharacter("9")}
	@IBAction func button0Pressed(sender: AnyObject) {playSound(); insertCharacter("0")}
	
	func playSound()
	{
		AudioServicesPlaySystemSound(1104)
	}
}