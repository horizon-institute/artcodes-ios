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
import UIKit
import ArtcodesScanner

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
		
    init()
	{
        super.init(nibName:"ExperienceEditInfoViewController", bundle:nil)
        title = "Info"
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
        experienceDescription.text = experience.description
		if experience.description != nil
		{
			experienceDescription.textColor = UIColor.black
		}
		else
		{
			experienceDescription.textColor = UIColor.lightGray
			experienceDescription.text = "Description"
		}
		
        experienceImage.loadURL(url: experience.image)
        experienceIcon.loadURL(url: experience.icon)
		
        NotificationCenter.default.addObserver(self, selector: #selector(ExperienceEditInfoViewController.keyboardNotification(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(ExperienceEditInfoViewController.keyboardNotification(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil);
	}
	
    override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Add toolbars above the keyboard:
        experienceTitle.inputAccessoryView = createKeyboardToolBar(selector: #selector(nextPressedOnTitle), buttonText: "Next")
        experienceDescription.inputAccessoryView = createKeyboardToolBar(selector: #selector(nextPressedOnDesc), buttonText: nextCallback==nil ? "Done" : "Next")
	}
	
	@IBAction func selectIcon(_ sender: Any)
	{
		let imagePicker = UIImagePickerController()
		imagePicker.view.tag = 2
		imagePicker.delegate = self
		imagePicker.allowsEditing = false
		imagePicker.sourceType = .photoLibrary
		
        present(imagePicker, animated: true, completion: nil)
	}
	
	@IBAction func selectImage(_ sender: Any)
	{
		let imagePicker = UIImagePickerController()
		imagePicker.view.tag = 1
		imagePicker.delegate = self
		imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
		
        present(imagePicker, animated: true, completion: nil)
	}
	
    func textViewDidBeginEditing(_ textView: UITextView)
	{
        if textView.textColor == UIColor.lightGray
		{
			textView.text = nil
			textView.textColor = UIColor.black
		}
	}
	
    func textViewDidEndEditing(_ textView: UITextView)
	{
		if textView.text.isEmpty
		{
			textView.text = "Description"
			textView.textColor = UIColor.lightGray
		}
		else
		{
			experience.description = textView.text
		}
	}
	
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
	{
        if let imageURL = info[.imageURL] as? URL
		{
			if picker.view.tag == 1
			{
                print("Image selected")

				experience.image = imageURL.absoluteString
                experienceImage.loadURL(url: experience.image)
			}
			else if picker.view.tag == 2
			{
                print("Icon selected")
				experience.icon = imageURL.absoluteString
                experienceIcon.loadURL(url: experience.icon)
			}
		}
		
        dismiss(animated: true, completion: nil)
	}
	
	deinit
	{
        NotificationCenter.default.removeObserver(self)
	}
	
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		experienceDescription.becomeFirstResponder()
		return false
	}
	
    @objc func keyboardNotification(notification: NSNotification)
	{
        let isShowing = notification.name == UIResponder.keyboardWillShowNotification
		
		if let userInfo = notification.userInfo
		{
            if let keyboardSize = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue
			{
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: isShowing ? keyboardSize.cgRectValue.height + toolbarHeight : 0, right: 0)
				scrollView.contentInset = insets
				scrollView.scrollIndicatorInsets = insets
			}
		}
	}
	
    func textViewDidChangeSelection(_ textView: UITextView)
	{
		textView.layoutIfNeeded()
		textView.scrollRangeToVisible(textView.selectedRange)
	}
	
    func textFieldDidEndEditing(_ textField: UITextField)
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
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        let doneButton = UIBarButtonItem(title: buttonText, style: UIBarButtonItem.Style.done, target: self, action: selector)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
		toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
		toolBar.sizeToFit()
		
		return toolBar
	}
	
    @objc func nextPressedOnTitle(){
		self.experienceDescription.becomeFirstResponder()
	}
    
    @objc func nextPressedOnDesc(){
		view.endEditing(true)
		if let nextClosure = nextCallback
		{
			nextClosure()
		}
	}
}
