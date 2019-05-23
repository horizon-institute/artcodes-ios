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
import ArtcodesScanner
import Alamofire
import AlamofireImage

class ExperienceViewController: GAITrackedViewController, UITabBarDelegate
{
	@IBOutlet weak var experienceImage: UIImageView!
	@IBOutlet weak var experienceIcon: UIImageView!
	@IBOutlet weak var experienceTitle: UILabel!
	@IBOutlet weak var experienceDescription: UILabel!
	@IBOutlet weak var buttonBar: UITabBar!
	@IBOutlet weak var imageProgress: UIActivityIndicatorView!
	@IBOutlet weak var imageHeight: NSLayoutConstraint!
	@IBOutlet weak var experienceLocations: UIView!
	@IBOutlet weak var saveIndicator: UIActivityIndicatorView!

	@IBOutlet weak var originExperienceIcon: UIImageView!
	@IBOutlet weak var originExperienceTitle: UILabel!
	@IBOutlet weak var originHeight: NSLayoutConstraint!
	
	
	@objc var experience: Experience!
	@objc var originExperience: Experience?
	
	@objc init(experience: Experience)
	{
		super.init(nibName:"ExperienceViewController", bundle:nil)
		self.experience = experience
		self.extendedLayoutIncludesOpaqueBars = true
		self.automaticallyAdjustsScrollViewInsets = false
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
        screenName = "View Experience"
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		buttonBar.backgroundImage = UIImage()
		buttonBar.shadowImage = UIImage()
		buttonBar.tintColor = UIColor.black
		
		experience.callback = updateExperience
		
		//navigationController?.setNavigationBarHidden(true, animated: animated)
		
		navigationController?.navigationBar.setBackgroundImage(UIImage(named: "shim"), for: .default)
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationController?.navigationBar.isTranslucent = true
		navigationController?.view.backgroundColor = UIColor.clear
		navigationController?.navigationBar.backgroundColor = UIColor.clear
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"ic_arrow_back_white"), style: .plain, target: self, action: #selector(ExperienceViewController.back))
		
		updateExperience()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// force the screen to portrait orientation if the image covers the whole screen
		if experienceImage.frame.height > self.view.frame.height {
			let value = UIInterfaceOrientation.portrait.rawValue
			UIDevice.current.setValue(value, forKey: "orientation")
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		experience.callback = nil
	
		navigationController?.navigationBar.isTranslucent = false
		navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
	}
	
	@objc func back()
	{
		_ = navigationController?.popViewController(animated: true)
	}
	
	@objc func updateExperience()
	{
		var barItems: [UITabBarItem] = []
		
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			if appDelegate.server.isSaving(experience)
			{
				saveIndicator.isHidden = false
				buttonBar.isHidden = true
			}
			else
			{
				saveIndicator.isHidden = true
				buttonBar.isHidden = false
				if appDelegate.server.canEdit(experience)
				{
					barItems.append(UITabBarItem(title: "Edit", image: UIImage(named: "ic_edit_18pt"), tag: 1))
				}

				var accounts = 0
				let accountIDs =  appDelegate.server.accounts.keys.sorted()
				for id in accountIDs
				{
					if let account = appDelegate.server.accounts[id]
					{
						if !account.canEdit(experience)
						{
							accounts += 1
						}
					}
				}

				if accounts > 0 && (experience.canCopy ?? true)
				{
					barItems.append(UITabBarItem(title: "Copy", image: UIImage(named: "ic_folder_move_18pt"), tag: 2))
				}
				
				if let id = experience.id
				{
					if appDelegate.server.starred.contains(id)
					{
						barItems.append(UITabBarItem(title: "Unstar", image: UIImage(named: "ic_star_18pt"), tag: 3))
					}
					else
					{
						barItems.append(UITabBarItem(title: "Star", image: UIImage(named: "ic_star_border_18pt"), tag: 3))
					}
				}
				
				if !LocalAccount().canEdit(experience)
				{
					barItems.append(UITabBarItem(title: "Share", image: UIImage(named: "ic_share_18pt"), tag: 4))
				}
			}
		}
		
		buttonBar.setItems(barItems, animated: true)
		
		for barItem in buttonBar.items!
		{
			if let image = barItem.image
			{
				barItem.image = image.withRenderingMode(.alwaysOriginal)
			}
			barItem.setTitleTextAttributes(convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.black]), for: UIControl.State())
		}
		
		// Do any additional setup after loading the view.
		experienceTitle.text = experience.name
		experienceDescription.text = experience.experienceDescription
		if let imageURL = experience.image
		{
			experienceImage.backgroundColor = UIColor.clear
			experienceImage.loadURL(imageURL) {
			(image) in
			self.imageProgress.stopAnimating()
			if let result = image
			{
				let ratio = result.size.width / result.size.height
				
				let aspectConstraint = NSLayoutConstraint(item: self.experienceImage, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.experienceImage, attribute: NSLayoutConstraint.Attribute.height, multiplier: ratio, constant: 0)
				self.experienceImage.addConstraint(aspectConstraint)
			}
			else
			{
				self.imageHeight.constant = 0
			}
		}
		}
		else
		{
			experienceImage.backgroundColor = UIColor(hex6: 0x324A5E)
		}
		experienceIcon.loadURL(experience.icon)
		
		experienceLocations.subviews.forEach { $0.removeFromSuperview() }
		
		var lastView : UIView?
		for availability in experience.availabilities
		{
			if availability.lat != nil && availability.lon != nil && availability.name != nil
			{
				if let placeView = Bundle.main.loadNibNamed("PlaceView", owner: self, options: nil)![0] as? PlaceView
				{
					placeView.availability = availability
					placeView.translatesAutoresizingMaskIntoConstraints = false
					experienceLocations.addSubview(placeView)
					
					if let previousView = lastView
					{
						experienceLocations.addConstraint(NSLayoutConstraint(item: placeView, attribute: .top,
							relatedBy: .equal,
							toItem: previousView, attribute: .bottom,
							multiplier: 1.0,
							constant: 0.0))
					}
					else
					{
						experienceLocations.addConstraint(NSLayoutConstraint(item: placeView, attribute: .top,
							relatedBy: .equal,
							toItem: experienceLocations, attribute: .top,
							multiplier: 1.0,
							constant: 8.0))
					}
					
					experienceLocations.addConstraint(NSLayoutConstraint(item: placeView, attribute: .left,
						relatedBy: .equal,
						toItem: experienceLocations, attribute: .left,
						multiplier: 1.0,
						constant: 0.0))
					experienceLocations.addConstraint(NSLayoutConstraint(item: placeView, attribute: .right,
						relatedBy: .equal,
						toItem: experienceLocations, attribute: .right,
						multiplier: 1.0,
						constant: 0.0))
					
					lastView = placeView
				}
			}
		}
		
		if let previousView = lastView
		{
			let finalConstraint = NSLayoutConstraint(item: previousView, attribute: .bottom,
			                                         relatedBy: .equal,
			                                         toItem: experienceLocations, attribute: .bottom,
			                                         multiplier: 1.0,
			                                         constant: 0.0)
			finalConstraint.priority = UILayoutPriority(rawValue: 500)
			experienceLocations.addConstraint(finalConstraint)
		}
		
		view.layoutIfNeeded()
		
		if let origin = self.experience.originalID
		{
			NSLog("Original ID: %@", "\(origin)")
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				appDelegate.server.loadExperience(origin, success: { (experience) in
					var url: URL?
					if let image = experience.icon
					{
						url = URL(string: image)
					}
					else if let image = experience.image
					{
						url = URL(string: image)
					}
					
					if let imageURL = url
					{
						self.originExperienceIcon.af_setImage(withURL: imageURL)
					}
					self.originExperienceTitle.text = experience.name
					self.originHeight.priority = UILayoutPriority(rawValue: 250)
					self.originExperience = experience
					
					}, failure: { (error) in
						NSLog("Error: %@", "\(error)")
				})
			}
		}
		else
		{
			self.originHeight.priority = UILayoutPriority(rawValue: 900)
		}
	}
	
	@objc func copyTo(_ item: UITabBarItem)
	{
		if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
		{
			let accountMenu = UIAlertController(title: "Copy to Library", message: nil, preferredStyle: .actionSheet)
			
			let accountIDs =  appDelegate.server.accounts.keys.sorted()
			for id in accountIDs
			{
				if let account = appDelegate.server.accounts[id]
				{
					if !account.canEdit(experience)
					{
						accountMenu.addAction(UIAlertAction(title: account.name, style: .default, handler: { (alert: UIAlertAction) -> Void in
							self.experience.originalID = self.experience.id
							self.experience.id = nil
							if let name = self.experience.name
							{
								self.experience.name = "Copy of " + name
							}
							self.experience.availabilities = [];
							account.saveExperience(self.experience)
							self.updateExperience()
						}))
					}
				}
			}
			
			accountMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			accountMenu.popoverPresentationController?.sourceView = buttonBar
			accountMenu.popoverPresentationController?.sourceRect = tabitemRect(item)
			present(accountMenu, animated: true, completion: nil)
		}
	}
	
	func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
	{
		if item.tag == 1
		{
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				if(!appDelegate.server.isSaving(experience))
				{
					navigationController?.pushViewController(ExperienceEditViewController(experience: experience, account: appDelegate.server.accountFor(experience)), animated: true)
				}
			}
		}
		else if item.tag == 2
		{
			copyTo(item)
		}
		else if item.tag == 3
		{
			if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
			{
				if let id = experience.id
				{
					var starred =  appDelegate.server.starred
					if starred.contains(id)
					{
						starred.removeObject(id)
						appDelegate.server.starred = starred
						updateExperience()
					}
					else
					{
						starred.append(id)
						appDelegate.server.starred = starred
						updateExperience()
					}
				}
			}
		}
		else if item.tag == 4
		{
			if var id = experience.id
			{
				id = id.replacingOccurrences(of: "://aestheticodes.appspot.com/experience/", with: "://aestheticodes.appspot.com/experience/info/")
				if let experienceURL = URL(string: id)
				{
					let controller = UIActivityViewController(activityItems: [experience.name!, experienceURL], applicationActivities: nil)
					controller.popoverPresentationController?.sourceView = buttonBar
					controller.popoverPresentationController?.sourceRect = tabitemRect(item)
					
					present(controller, animated: true, completion: nil)
				}
			}
		}
	}
	
	@objc func isTabButton(_ view: UIView, item: UITabBarItem) -> Bool
	{
		for subview in view.subviews
		{
			if let label = subview as? UILabel
			{
				if label.text == item.title
				{
					return true
				}
			}
			else if isTabButton(subview, item: item)
			{
				return true
			}
		}
		return false
	}
	
	@objc func tabitemRect(_ item: UITabBarItem) -> CGRect
	{
		for tabButton in buttonBar.subviews
		{
			if isTabButton(tabButton, item: item)
			{
				return tabButton.frame
			}
		}
		return buttonBar.frame
	}
	
	@IBAction func scanExperience(_ sender: AnyObject)
	{
		navigationController?.pushViewController(ArtcodeViewController(experience: experience), animated: true)
	}

	@IBAction func openOrigin(_ sender: AnyObject)
	{
		if let origin = originExperience
		{
			navigationController?.pushViewController(ExperienceViewController(experience: origin), animated: true)
		}
	}
	
    override func didReceiveMemoryWarning()
	{
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
