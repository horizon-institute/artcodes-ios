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
	@IBOutlet weak var experienceImage: UIImageView!
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var experienceTitle: UITextField!
	@IBOutlet weak var experienceDescription: UITextView!
	
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
		experienceDescription.text = experience.description
        
        if let imageURL = experience.image
        {
            if let url = NSURL(string: imageURL)
            {
                experienceImage.af_setImageWithURL(url)
            }
            
        }
        if let iconURL = experience.icon
        {
            if let url = NSURL(string: iconURL)
            {
                experienceIcon.af_setImageWithURL(url)
            }
        }
	}
	
	func textFieldDidBeginEditing(textField: UITextField)
	{
		scrollView.scrollRectToVisible(textField.bounds, animated: true)
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        NSLog("image selected")
        if let imageURL = info[UIImagePickerControllerReferenceURL] as? NSURL
        {
            if picker.view.tag == 1
            {
                NSLog("%@", imageURL)
                experience.image = imageURL.absoluteString
                experienceImage.af_setImageWithURL(imageURL)
            }
            else if picker.view.tag == 2
            {
                NSLog("%@", imageURL)
                experience.icon = imageURL.absoluteString
                experienceIcon.af_setImageWithURL(imageURL)
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
	
	func textViewDidBeginEditing(textView: UITextView)
	{
		
	}
	
	func textViewDidChangeSelection(textView: UITextView)
	{
		textView.layoutIfNeeded()
		textView.scrollRangeToVisible(textView.selectedRange)
	}
	
	func textFieldDidEndEditing(textField: UITextField)
	{
		
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
