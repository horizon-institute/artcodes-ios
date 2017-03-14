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

class ExperienceEditInfoViewController: ExperienceEditBaseViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
	var nextCallback: (()->())? = nil
	var toolbarHeight: CGFloat = 0
	
	@IBOutlet weak var experienceImage: UIImageView!
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var experienceTitle: UITextField!
	@IBOutlet weak var experienceDescription: UITextView!
	
	@IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
	
	override var name: String
		{
			return "Info"
	}
	
	init()
	{
		super.init(nibName:"ExperienceEditInfoViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		experienceTitle.text = experience.name
		experienceDescription.text = experience.experienceDescription
		if experience.experienceDescription != nil
		{
			experienceDescription.textColor = UIColor.blackColor()
		}
		else
		{
			experienceDescription.textColor = UIColor.lightGrayColor()
			experienceDescription.text = "Description"
		}
		
		experienceImage.loadURL(experience.image)
		experienceIcon.loadURL(experience.icon)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ExperienceEditInfoViewController.keyboardNotification(_:)), name:UIKeyboardWillShowNotification, object: nil);
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ExperienceEditInfoViewController.keyboardNotification(_:)), name:UIKeyboardWillHideNotification, object: nil);
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		// Add toolbars above the keyboard:
		experienceTitle.inputAccessoryView = createKeyboardToolBar(#selector(nextPressedOnTitle), buttonText: "Next")
		experienceDescription.inputAccessoryView = createKeyboardToolBar(#selector(nextPressedOnDesc), buttonText: nextCallback==nil ? "Done" : "Next")
	}
	
	@IBAction func selectIcon(sender: AnyObject)
	{
		let imagePicker = UIImagePickerController()
		imagePicker.view.tag = 2
		imagePicker.delegate = self
		imagePicker.allowsEditing = false
		imagePicker.sourceType = .PhotoLibrary
		
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func selectImage(sender: AnyObject)
	{
		let imagePicker = UIImagePickerController()
		imagePicker.view.tag = 1
		imagePicker.delegate = self
		imagePicker.allowsEditing = false
		imagePicker.sourceType = .PhotoLibrary
		
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	func textViewDidBeginEditing(textView: UITextView)
	{
		if textView.textColor == UIColor.lightGrayColor()
		{
			textView.text = nil
			textView.textColor = UIColor.blackColor()
		}
	}
	
	func textViewDidEndEditing(textView: UITextView)
	{
		if textView.text.isEmpty
		{
			textView.text = "Description"
			textView.textColor = UIColor.lightGrayColor()
		}
		else
		{
			experience.experienceDescription = textView.text
		}
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
	{
		NSLog("image selected")
		if let imageURL = info[UIImagePickerControllerReferenceURL] as? NSURL
		{
			if picker.view.tag == 1
			{
				NSLog("%@", imageURL)
				experience.image = imageURL.absoluteString
				experienceImage.loadURL(experience.image)
			}
			else if picker.view.tag == 2
			{
				NSLog("%@", imageURL)
				experience.icon = imageURL.absoluteString
				experienceIcon.loadURL(experience.icon)
			}
		}
		
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	deinit
	{
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		experienceDescription.becomeFirstResponder()
		return false
	}
	
	func keyboardNotification(notification: NSNotification)
	{
		let isShowing = notification.name == UIKeyboardWillShowNotification
		
		if let userInfo = notification.userInfo
		{
			if let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue
			{
				let insets = UIEdgeInsets(top: 0, left: 0, bottom: isShowing ? keyboardSize.CGRectValue().height + toolbarHeight : 0, right: 0)
				scrollView.contentInset = insets
				scrollView.scrollIndicatorInsets = insets
			}
		}
	}
	
	func textViewDidChangeSelection(textView: UITextView)
	{
		textView.layoutIfNeeded()
		textView.scrollRangeToVisible(textView.selectedRange)
	}
	
	func textFieldDidEndEditing(textField: UITextField)
	{
		experience.name = textField.text
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// Keyboard toolbar functions:
	func createKeyboardToolBar(selector:Selector, buttonText:String) -> UIToolbar {
		let toolBar = UIToolbar()
		toolBar.barStyle = UIBarStyle.Default
		toolBar.translucent = true
		let doneButton = UIBarButtonItem(title: buttonText, style: UIBarButtonItemStyle.Done, target: self, action: selector)
		let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
		toolBar.setItems([spaceButton, doneButton], animated: false)
		toolBar.userInteractionEnabled = true
		toolBar.sizeToFit()
		
		return toolBar
	}
	
	func nextPressedOnTitle(){
		self.experienceDescription.becomeFirstResponder()
	}
	func nextPressedOnDesc(){
		view.endEditing(true)
		if let nextClosure = nextCallback
		{
			nextClosure()
		}
	}
}
