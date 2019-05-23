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
	@objc var textFieldToWorkOn: UITextField? = nil;
	@objc var autoColon = true
	
	@IBOutlet weak var colonButton: UIButton!
	
	init()
	{
		super.init(nibName: "CodeKeyboard", bundle: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		
		let longPress_gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(handleBtnLongPressGesture))
		colonButton.addGestureRecognizer(longPress_gesture)
	}
	
	@objc func handleBtnLongPressGesture(_ recognizer: UILongPressGestureRecognizer)
	{
		if recognizer.state == UIGestureRecognizer.State.ended
		{
			autoColon = !autoColon
			if (autoColon)
			{
				colonButton.backgroundColor = UIColor(hue: 200.0/360.0, saturation: 15.0/100.0, brightness: 1, alpha: 1)
			}
			else
			{
				colonButton.backgroundColor = UIColor.white
			}
			playSound()
		}
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
	}
	
	@objc func insertCharacter(_ c:String)
	{
		if let nonNilTextField = self.textFieldToWorkOn
		{
			if let delegate = nonNilTextField.delegate
			{
				let beginning: UITextPosition = nonNilTextField.beginningOfDocument
				
				let selectedRange: UITextRange = nonNilTextField.selectedTextRange!
				let selectionStart: UITextPosition = selectedRange.start
				let selectionEnd: UITextPosition = selectedRange.end
				
				let location: NSInteger = nonNilTextField.offset(from: beginning, to:selectionStart)
				let length:   NSInteger = nonNilTextField.offset(from: selectionStart, to:selectionEnd)
				
				let range = NSMakeRange(location, length)
				
				var stringToInsert = c
				if (autoColon && c != ":")
				{
					let text: String = nonNilTextField.text!
					// insert colon before
                    if !(location == 0 || text.substring(with: text.index(text.startIndex, offsetBy: location-1)..<text.index(text.startIndex, offsetBy: location)) == ":")
					{
						stringToInsert = ":" + stringToInsert
					}
					// insert colon after
					if text.endIndex == text.index(text.startIndex, offsetBy: location+length) || !(text.substring(with: text.index(text.startIndex, offsetBy: location+length)..<text.index(text.startIndex, offsetBy: location+length+1)) == ":")
					{
						stringToInsert = stringToInsert + ":"
					}
				}
				
				if (delegate.textField!(nonNilTextField, shouldChangeCharactersIn: range, replacementString: stringToInsert))
				{
					nonNilTextField.insertText(stringToInsert)
				}
			}
			else
			{
				nonNilTextField.insertText(c)
			}
		}
	}
	
	
	@objc func removeCharacter()
	{
		if let nonNilTextField = self.textFieldToWorkOn
		{
			if let delegate = nonNilTextField.delegate
			{
				let beginning: UITextPosition = nonNilTextField.beginningOfDocument
				
				let selectedRange: UITextRange = nonNilTextField.selectedTextRange!
				let selectionStart: UITextPosition = selectedRange.start
				let selectionEnd: UITextPosition = selectedRange.end
				
				let location: NSInteger = nonNilTextField.offset(from: beginning, to:selectionStart)
				let length:   NSInteger = nonNilTextField.offset(from: selectionStart, to:selectionEnd)
				
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
				
				if (delegate.textField!(nonNilTextField, shouldChangeCharactersIn: range, replacementString: ""))
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
	
	@objc func addAutoColon(_ string: String) -> String
	{
		if self.autoColon
		{
			return string + ":"
		}
		else
		{
			return string
		}
	}
	
	@IBAction func button1Pressed(_ sender: AnyObject) {playSound(); insertCharacter("1")}
	@IBAction func button2Pressed(_ sender: AnyObject) {playSound(); insertCharacter("2")}
	@IBAction func button3Pressed(_ sender: AnyObject) {playSound(); insertCharacter("3")}
	@IBAction func buttonBSPressed(_ sender: AnyObject) {playSound(); removeCharacter()}
	
	@IBAction func button4Pressed(_ sender: AnyObject) {playSound(); insertCharacter("4")}
	@IBAction func button5Pressed(_ sender: AnyObject) {playSound(); insertCharacter("5")}
	@IBAction func button6Pressed(_ sender: AnyObject) {playSound(); insertCharacter("6")}
	@IBAction func buttonRegionSeperatorPressed(_ sender: AnyObject) {playSound(); insertCharacter(":")}
	
	@IBAction func button7Pressed(_ sender: AnyObject) {playSound(); insertCharacter("7")}
	@IBAction func button8Pressed(_ sender: AnyObject) {playSound(); insertCharacter("8")}
	@IBAction func button9Pressed(_ sender: AnyObject) {playSound(); insertCharacter("9")}
	@IBAction func button0Pressed(_ sender: AnyObject) {playSound(); insertCharacter("0")}
	
	@objc func playSound()
	{
		AudioServicesPlaySystemSound(1104)
	}
}
