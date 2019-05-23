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

/**
View Controller for UI for editing a pipeline containing a method for: greyscaling the input, thresholding and detecting markers. Note this UI only handles one of each type and adds them if not present.
*/
class ExperienceEditPipelineViewController: ExperienceEditBaseViewController, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource
{
	@IBOutlet weak var scrollView: UIScrollView!
	
	@IBOutlet weak var detectField: UITextField!
	@IBOutlet weak var thresholdField: UITextField!
	@IBOutlet weak var greyscaleField: UITextField!
	
	@objc let colorPickerView = UIPickerView()
	@objc let thresholdPickerView = UIPickerView()
	@objc let detectPickerView = UIPickerView()
	
	var colorFilterPositionInPipeline: Int? = nil
	var thresholdPositionInPipeline: Int? = nil
	var detectPositionInPipeline: Int? = nil
	
	@objc let colorFilterMethodsInOrder: [String] = ["intensity", "redFilter", "greenFilter", "blueFilter", "cyanKFilter", "magentaKFilter", "yellowKFilter", "blackKFilter"]
	@objc let colorFilterMethods: [String:String] = [
		"intensity":      "Intensity (default)",
		"redFilter":      "Red filter",
		"greenFilter":    "Green filter",
		"blueFilter":     "Blue filter",
		"cyanKFilter":    "Cyan (CMYK) filter",
		"magentaKFilter": "Magenta (CMYK) filter",
		"yellowKFilter":  "Yellow (CMYK) filter",
		"blackKFilter":   "Black (CMYK) filter"
	]
	
	
	@objc let thresholdMethodsInOrder: [String] = ["tile", "OTSU"]
	@objc let thresholdMethods: [String:String] = [
		"tile": "Tile (default)",
		"OTSU": "Otsu's Method"
	]
	
	@objc let detectMethodsInOrder: [String] = ["detect", "detectEmbedded", "detectEmbedded(embeddedOnly)", "detectEmbedded(relaxed)", "detectOrdered", "detectEmbeddedOrdered", "detectDebug"]
	@objc let detectMethods: [String:String] = [
		"detect": "Artcodes (default)",
		"detectEmbedded": "Visual Checksum (optional)",
		"detectEmbedded(embeddedOnly)": "Visual Checksum (only)",
		"detectEmbedded(relaxed)": "Visual Checksum (relaxed)",
		"detectOrdered": "Area Order (angles)",
		"detectEmbeddedOrdered": "Visual CS+Area (angles)",
		"detectDebug": "Artcodes Debug"
	]
	
	override var name: String
	{
		return "Pipeline"
	}
	
	init()
	{
		super.init(nibName:"ExperienceEditPipelineViewController", bundle:nil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// setup picker views:
		
		colorPickerView.dataSource = self
		colorPickerView.delegate = self
		self.greyscaleField.inputView = colorPickerView;
		self.greyscaleField.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: "", buttonText: "Next")
		
		thresholdPickerView.dataSource = self
		thresholdPickerView.delegate = self
		self.thresholdField.inputView = thresholdPickerView;
		self.thresholdField.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: "", buttonText: "Next")
		
		detectPickerView.dataSource = self
		detectPickerView.delegate = self
		self.detectField.inputView = detectPickerView;
		self.detectField.inputAccessoryView = self.createKeyboardToolBar(self, selector: #selector(moveToNextTextField), helpText: "", buttonText: "Done")
		
		// find the 3 methods in the pipeline:
		
		var colourFound = false
		var thresholdFound = false
		var detectFound = false
		for pipelineIndex in 0..<experience.pipeline.count
		{
			let pipelineItem: String = experience.pipeline[pipelineIndex]
			
			if let pipelineItemDisplayName = colorFilterMethods[pipelineItem]
			{
				self.greyscaleField.text = pipelineItemDisplayName
				colorFilterPositionInPipeline = pipelineIndex
				colorPickerView.selectRow(colorFilterMethodsInOrder.firstIndex(of: pipelineItem)!, inComponent: 0, animated: false)
				colourFound = true
			}
			else if let pipelineItemDisplayName = thresholdMethods[pipelineItem]
			{
				self.thresholdField.text = pipelineItemDisplayName
				thresholdPositionInPipeline = pipelineIndex
				thresholdPickerView.selectRow(thresholdMethodsInOrder.firstIndex(of: pipelineItem)!, inComponent: 0, animated: false)
				thresholdFound = true
			}
			else if let pipelineItemDisplayName = detectMethods[pipelineItem]
			{
				self.detectField.text = pipelineItemDisplayName
				detectPositionInPipeline = pipelineIndex
				detectPickerView.selectRow(detectMethodsInOrder.firstIndex(of: pipelineItem)!, inComponent: 0, animated: false)
				detectFound = true
			}
				
				// also look for values the current version of the app might not understand but probably match our 3 types so we don't insert extra items into the pipeline later
			else if !colourFound && pipelineItem.lowercased().contains("filter")
			{
				self.greyscaleField.text = pipelineItem
				colorFilterPositionInPipeline = pipelineIndex
			}
			else if !thresholdFound && pipelineItem.lowercased().contains("threshold")
			{
				self.thresholdField.text = pipelineItem
				thresholdPositionInPipeline = pipelineIndex
			}
			else if !detectFound && pipelineItem.lowercased().contains("detect")
			{
				self.detectField.text = pipelineItem
				detectPositionInPipeline = pipelineIndex
			}
		}
		
		// if the 3 methods were not found add them:
		
		if self.detectPositionInPipeline == nil
		{
			experience.pipeline.insert(detectMethodsInOrder[0], at: experience.pipeline.count)
			self.detectPositionInPipeline = experience.pipeline.count - 1
		}
		
		if self.thresholdPositionInPipeline == nil
		{
			experience.pipeline.insert(thresholdMethodsInOrder[0], at: self.detectPositionInPipeline!)
			self.thresholdPositionInPipeline = self.detectPositionInPipeline
			self.detectPositionInPipeline = self.detectPositionInPipeline! + 1
		}
		
		if self.colorFilterPositionInPipeline == nil
		{
			experience.pipeline.insert(colorFilterMethodsInOrder[0], at: 0)
			self.colorFilterPositionInPipeline = 0
			self.thresholdPositionInPipeline = self.thresholdPositionInPipeline! + 1
			self.detectPositionInPipeline = self.detectPositionInPipeline! + 1
		}
		
		self.updatePipelineFields()
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// UIPickerView functions:
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
	{
		if pickerView == self.colorPickerView
		{
			return colorFilterMethods[colorFilterMethodsInOrder[row]]
		}
		else if pickerView == self.thresholdPickerView
		{
			return thresholdMethods[thresholdMethodsInOrder[row]]
		}
		else if pickerView == self.detectPickerView
		{
			return detectMethods[detectMethodsInOrder[row]]
		}
		return nil
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		if pickerView == self.colorPickerView
		{
			return colorFilterMethods.count
		}
		else if pickerView == self.thresholdPickerView
		{
			return thresholdMethods.count
		}
		else if pickerView == self.detectPickerView
		{
			return detectMethods.count
		}
		return 0
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
		if pickerView == self.colorPickerView
		{
			experience.pipeline[self.colorFilterPositionInPipeline!] = colorFilterMethodsInOrder[row]
		}
		else if pickerView == self.thresholdPickerView
		{
			experience.pipeline[self.thresholdPositionInPipeline!] = thresholdMethodsInOrder[row]
		}
		else if pickerView == self.detectPickerView
		{
			experience.pipeline[self.detectPositionInPipeline!] = detectMethodsInOrder[row]
		}
		
		self.updatePipelineFields()
	}
	
	@objc func updatePipelineFields()
	{
		self.greyscaleField.text = self.colorFilterMethods[experience.pipeline[self.colorFilterPositionInPipeline!]] ?? experience.pipeline[self.colorFilterPositionInPipeline!]
		self.thresholdField.text = self.thresholdMethods[experience.pipeline[self.thresholdPositionInPipeline!]] ?? experience.pipeline[self.thresholdPositionInPipeline!]
		self.detectField.text = self.detectMethods[experience.pipeline[self.detectPositionInPipeline!]] ?? experience.pipeline[self.detectPositionInPipeline!]
	}
	
	// end of UIPickerView functions
	
	
	// Keyboard toolbar functions:
	@objc func createKeyboardToolBar(_ target: AnyObject, selector:Selector, helpText:String, buttonText:String) -> UIToolbar
	{
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
		
		return toolBar
	}
	@objc func moveToNextTextField()
	{
		if self.greyscaleField.isFirstResponder
		{
			self.thresholdField.becomeFirstResponder()
		}
		else if self.thresholdField.isFirstResponder
		{
			self.detectField.becomeFirstResponder()
		}
		else if self.detectField.isFirstResponder
		{
			self.detectField.resignFirstResponder()
		}
	}
	
}
