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
    let codeChars = CharacterSet(charactersIn: "0123456789:.")
	
	@IBOutlet weak var actionName: UITextField!
	@IBOutlet weak var actionURL: UITextField!
	@IBOutlet weak var matchTypeField: UITextField!
	@IBOutlet weak var codesView: UIView!
	@IBOutlet weak var newCode: UITextField!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var permissionHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var newCodeHeightConstraint: NSLayoutConstraint!
	
	var viewController: ActionListViewController!
	var action: Action
	let index: Int
	
	//let codeKeyboardViewController: CodeKeyboardViewController = CodeKeyboardViewController();
	
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
        
		actionName.text = action.name
		actionURL.text = action.displayURL
		
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShown(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHidden(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil);
		
		actionName.becomeFirstResponder()
		
		self.updateMatchField()
        if Feature.isEnabled(feature: "feature_combined_codes")
		{
			let pickerView = UIPickerView()
			pickerView.dataSource = self
			pickerView.delegate = self
            pickerView.selectRow(intForMatchType(match: action.match ?? Match.any), inComponent: 0, animated: false);
			self.matchTypeField.inputView = pickerView;
            self.matchTypeField.isEnabled = true
		}
		else
		{
            self.matchTypeField.isEnabled = false
		}
		
        self.actionName.inputAccessoryView = self.createKeyboardToolBar(target: self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_name, buttonText: self.button_string_next).tooblar
        self.actionURL.inputAccessoryView = self.createKeyboardToolBar(target: self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_url, buttonText: self.button_string_next).tooblar
        self.matchTypeField.inputAccessoryView = self.createKeyboardToolBar(target: self, selector: #selector(moveToNextTextField), helpText: self.toolbar_string_match_mode, buttonText: self.button_string_next).tooblar
        let newCodeToolbar = self.createKeyboardToolBar(target: self, selector: #selector(newCodeNextButtonPressed), helpText: self.toolbar_string_code, buttonText: self.button_string_done)
		self.newCode.inputAccessoryView = newCodeToolbar.tooblar
		self.changeNewCodeButtonText = newCodeToolbar.changeButtonTitle
	}
	
    @objc func newCodeNextButtonPressed()
	{
		
		if newCode.text == "" || newCode.text == nil
		{
			newCode.resignFirstResponder()
		}
		else
		{
            removeTrailingColon(textField: newCode)
			action.codes.append(newCode.text!)
            createCodes()
			newCode.text = ""
			newCode.becomeFirstResponder()
			self.changeNewCodeButtonText(self.button_string_done)
		}
	}
	
    override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
        createCodes()
	}
	
    @objc func keyboardShown(notification: NSNotification)
	{
		if let userInfo = notification.userInfo
		{
            if let keyboardSize = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue
			{
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.cgRectValue.height+100, right: 0)
				scrollView.contentInset = insets
				scrollView.scrollIndicatorInsets = insets
			}
		}
	}
	
	@IBAction func addCode(_ sender: Any)
	{
		let vc = AddCodeViewController(action: action)
        self.present(vc, animated: true, completion: nil)
	}
	
    @objc func keyboardHidden(notification:NSNotification)
	{
        scrollView.contentInset = UIEdgeInsets.zero;
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero;
	}
	
	@IBAction func pickerToolbarNextPressed(_ sender: Any) {
        textFieldShouldReturn(self.matchTypeField)
	}
	
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		NSLog("textField: %@", textField)
		if textField == actionName
		{
			actionURL.becomeFirstResponder()
		}
        else if textField == actionURL && Feature.isEnabled(feature: "feature_combined_codes")
		{
			matchTypeField.becomeFirstResponder()
		}
		else if textField == actionURL || textField == matchTypeField
		{
            if selectCodeEdit(index: 1)
			{
				return true
			}
			newCode.becomeFirstResponder()
		}
		else if textField == newCode
		{
			textField.endEditing(true)
		}
        else if textField.keyboardType == .numbersAndPunctuation // || textField.inputView == self.codeKeyboardViewController.view
		{
			NSLog("textField.tag: %@", textField.tag)
            if selectCodeEdit(index: textField.tag + 1)
			{
				return true
			}
			newCode.becomeFirstResponder()
		}
		return true
	}
	
	@IBAction func deleteAction(_ sender: Any)
	{
		actionName.becomeFirstResponder()
		actionName.resignFirstResponder()
        presentingViewController?.dismiss(animated: true, completion: { () -> Void in
            self.viewController.deleteAction(index: self.index)
		})
	}
	
	func textFromField(textField: UITextField) -> String?
	{
		if let text = textField.text
		{
            let trimmed = text.trimmingCharacters(in: CharacterSet.whitespaces)
			if trimmed.count > 0
			{
				return trimmed
			}
		}
		return nil
	}
	
	@IBAction func close(_ sender: Any)
	{
		actionName.becomeFirstResponder()
		actionName.resignFirstResponder()
		
		if newCode.text != nil && newCode.text != ""
		{
			action.codes.append(newCode.text!)
		}
		
		// remove empty strings & duplicates
        action.codes = Array(Set(action.codes.filter { $0 != "" }))
		if action.match != Match.sequence
		{
            action.codes.sort()
		}
		
        viewController?.experience.actions[index] = action
		viewController?.tableView.reloadData()
        presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	var currentTextField: UITextField? = nil
	
    func textFieldDidEndEditing(_ textField: UITextField)
	{
		if textField == actionName
		{
            action.name = textFromField(textField: textField)
		}
		else if textField == actionURL
		{
            if var url = textFromField(textField: textField)
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
        else if textField.textContentType == .oneTimeCode
		{
            removeTrailingColon(textField: textField)
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
                createCodes()
			}
		}
	}
	
	func removeTrailingColon(textField: UITextField)
	{
		print("removing trailing colon from \(textField.text ?? "")")
		if !(textField.text?.isEmpty ?? true)
		{
            textField.text = textField.text?.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
		}
	}
	
	func createCodes()
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
					
                    codeView.codeEdit.inputAccessoryView = self.createKeyboardToolBar(target: self, selector: #selector(moveToNextTextField), helpText: "Enter a code", buttonText: self.button_string_add_new_code).tooblar
					
					lastView = codeView
				}
				else if let codeView = Bundle.main.loadNibNamed("CodeView", owner: self, options: nil)![0] as? CodeView
				{
					print("create code view \(index+20000) lastview=\(lastView)")
					// TODO codeView.availability = availability
					codeView.codeEdit.text = code
					codeView.codeEdit.delegate = self
					codeView.codeEdit.tag = index
					codeView.tag = index + 20000
					codeView.translatesAutoresizingMaskIntoConstraints = false
					
					codesView.addSubview(codeView)
                    
                    var topConstraint: NSLayoutConstraint?
					if let previousView = lastView
					{
                        topConstraint = codeView.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 16)
					}
					else
					{
                        topConstraint = codeView.topAnchor.constraint(equalTo: codesView.topAnchor, constant: 16)
					}
                    
                    NSLayoutConstraint.activate([
                        topConstraint!,
                        codeView.rightAnchor.constraint(equalTo: codesView.safeAreaLayoutGuide.rightAnchor, constant: 16),
                        codeView.leftAnchor.constraint(equalTo: codesView.safeAreaLayoutGuide.leftAnchor, constant: 16),
                        codeView.heightAnchor.constraint(equalToConstant: 32.0)
                    ])
					
					lastView = codeView
				}
			}
		}
		
        if let heightConstraint = codesView.constraints.first(where: { $0.firstAttribute == .height }) {
            print("Remove Height Constraint")
            heightConstraint.isActive = lastView == nil
        }
        
		if let previousView = lastView
		{
            codesView.addConstraint(NSLayoutConstraint(item: previousView, attribute: .bottom,
                                                       relatedBy: .lessThanOrEqual,
                                                       toItem: codesView, attribute: .bottom,
				multiplier: 1.0,
				constant: 0.0))
		}
        codesView.updateConstraints()

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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	{
        NSLog("\(textField): \(string)")
        if textField.textContentType == .oneTimeCode {
            NSLog("true")
            if let text = textField.text {
                let result = text.replacingCharacters(in: Range(range, in: text)!, with: string).replacingOccurrences(of: ".", with: ":")
                // prevent double colons
                if string == ":" && (range.location == 0 || (range.location >= 1 && result[result.index(result.startIndex, offsetBy: range.location - 1)..<result.index(result.startIndex, offsetBy: range.location + 1)] == "::")) {
                    return false
                } else {
                    for uni in string.unicodeScalars {
                        if !codeChars.contains(uni) {
                            return false
                        }
                    }
                }
                
                changeNewCodeButtonText(result.isEmpty ? button_string_done : button_string_add_new_code)
            }
        }

		return true
	}
			
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField.textContentType == .oneTimeCode {
            textField.text = textField.text?.replacingOccurrences(of: ".", with: ":")
        }
    }
    
	// UIPickerView functions:
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
        return self.stringForMatchType(match: self.matchTypeForInt(n: row))
	}
	
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return 3
	}
	
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.action.match = self.matchTypeForInt(n: row)
		self.updateMatchField()
	}
	
	// Match type field functions:
	
	func updateMatchField()
	{
        self.matchTypeField.text = self.toolbar_string_match_mode + stringForMatchType(match: self.action.match ?? Match.any)
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
        @unknown default:
            fatalError()
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
        @unknown default:
            fatalError()
        }
	}
	
	
	// Keyboard toolbar functions:
	func createKeyboardToolBar(target: AnyObject, selector:Selector, helpText:String, buttonText:String) -> (tooblar: UIToolbar, changeButtonTitle: (String)->()) {
		let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        let helpButton = UIBarButtonItem(title: helpText, style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        helpButton.tintColor = UIColor.black
        let nextButton = UIBarButtonItem(title: buttonText, style: UIBarButtonItem.Style.plain, target: target, action: selector)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
		toolBar.setItems([helpButton, spaceButton, nextButton], animated: false)
        toolBar.isUserInteractionEnabled = true
		toolBar.sizeToFit()
		
		return (toolBar, {(title: String) -> () in nextButton.title = title })
	}
    
    @objc func moveToNextTextField()
	{
		if let currentTextField = self.currentTextField
		{
            if (currentTextField == self.actionName && self.actionName.isFirstResponder)
			{
				self.actionURL.becomeFirstResponder()
			}
            else if(currentTextField == self.actionURL && self.actionURL.isFirstResponder && Feature.isEnabled(feature: "feature_combined_codes"))
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
