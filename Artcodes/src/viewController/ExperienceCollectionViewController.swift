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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ExperienceCollectionViewController: GAITrackedViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
{
	var groups: [String: [String]] = [:]
	var experiences: [String: Experience] = [:]
	var keys: [String] = []
	var closures: [String: () -> Void] = [:]
	var sorted = false
	var ordering: [String]
	{
		return []
	}
	
	var colCount = 0
	{
		didSet
		{
			if(colCount != oldValue)
			{
				for section in groups.keys
				{
					if closures[section] != nil
					{
						reloadSection(section)
					}
				}
			}
		}
	}
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var fab: UIButton!
	@IBOutlet weak var progressView: UIActivityIndicatorView!
	@IBOutlet weak var errorView: UIView!
	@IBOutlet weak var errorIcon: UIImageView!
	@IBOutlet weak var errorMessage: UILabel!
	@IBOutlet weak var errorDetails: UILabel!
	
	var progress = 0
	{
		didSet
		{
			progressView.isHidden = progress == 0
			errorView.isHidden = progress != 0 || experiences.count != 0
		}
	}
	
	init()
	{
		super.init(nibName:"ExperienceCollectionViewController", bundle:nil)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
	{
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
	}
	
	func clear()
	{
		experiences = [:]
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		let items = itemsInSection(keys[section])
		return items
	}
	
	func itemsInSection(_ section: String) -> Int
	{
		if let experienceURIs = groups[section]
		{
			var count = 0
			for experienceURI in experienceURIs
			{
				if experiences.index(forKey: experienceURI) != nil
				{
					count += 1
				}
			}
			
			if closures[section] != nil
			{
				return min(colCount, count)
			}
			
			return count
		}
		return 0
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
	{
		super.viewWillTransition(to: size, with: coordinator)
		colCount = Int(size.width / 150)
		collectionView.collectionViewLayout.invalidateLayout()
		collectionView.reloadData()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
	{
		let collectionViewWidth = self.collectionView.bounds.size.width
		let span = Int(collectionViewWidth / 150)
		let width = (collectionViewWidth - CGFloat(16 * (span + 1))) / CGFloat(span)
		colCount = Int(collectionViewWidth / width)
		return CGSize(width: width, height: 130)
	}
	
	func reloadSection(_ section: String)
	{
		if var experienceURIs = groups[section]
		{
			if closures[section] != nil
			{
				experienceURIs = Array(experienceURIs.prefix(colCount))
			}
			for experienceURI in experienceURIs
			{
				//NSLog("Loading \(section) \(experienceURI)")
				if experiences.index(forKey: experienceURI) == nil
				{
					if let appDelegate = UIApplication.shared.delegate as? ArtcodeAppDelegate
					{
						progress += 1
						appDelegate.server.loadExperience(experienceURI,
						                                  success: { (experience) -> Void in
															var uri = experienceURI
															if experience.id != nil
															{
																uri = experience.id!
															}
															self.experiences[uri] = experience
															self.addSection(section)
															self.collectionView.reloadData()
															self.progress -= 1
							}, failure: { (error) -> Void in
								self.progress -= 1
								self.error(experienceURI, error: error)
						})
					}
				}
			}
		}
	}
	
	func addSection(_ section: String)
	{
		keys = []
		for key in ordering
		{
			if groups.index(forKey: key) != nil
			{
				if itemsInSection(key) > 0
				{
					keys.append(key)
				}
			}
		}
		
		for key in groups.keys
		{
			if !keys.contains(key)
			{
				if itemsInSection(key) > 0
				{
					keys.append(key)
				}
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView
	{
		switch kind
		{
		case UICollectionElementKindSectionHeader:
			let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderCell",
			                                                                       for: indexPath) as! HeaderCell
			let title = keys[indexPath.section]
			headerCell.title.text = NSLocalizedString(title, tableName: nil, bundle: Bundle.main, value: title.capitalized, comment: "")

			headerCell.more.isHidden = true
			if let closure = closures[title]
			{
				if groups[title]?.count > colCount
				{
					headerCell.more.isHidden = false
					headerCell.more.actionHandle(controlEvents: .touchUpInside, ForAction: closure)
				}
			}
			return headerCell
		case UICollectionElementKindSectionFooter:
			let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderCell",
			                                                                       for: indexPath) as! HeaderCell
			headerCell.title.text = ""
			return headerCell
		default:
			assert(false, "Unexpected element kind")
		}
		return UICollectionReusableView()
	}
	
	func numberOfSections(in collectionView: UICollectionView) -> Int
	{
		return keys.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		if let experience = experienceAt(indexPath)
		{
			let cell :ExperienceCardCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExperienceCardCell",  for: indexPath) as! ExperienceCardCell
			cell.experience = experience
			return cell;
		}
		
		return UICollectionViewCell()
	}
	
	func setExperienceURIs(_ experienceURIs: [String])
	{
		clear()
		if(experienceURIs.isEmpty)
		{
			collectionView.reloadData()
		}
		else
		{
			addExperienceURIs(experienceURIs, forGroup: "")
		}
	}
	
	func addExperienceURIs(_ experienceURIs: [String], forGroup: String, closure: (() -> Void)? = nil)
	{
		if experienceURIs.isEmpty
		{
			return
		}
		
		groups[forGroup] = experienceURIs
		
		if let moreClosure = closure
		{
			closures[forGroup] = moreClosure
		}
		
		reloadSection(forGroup)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		collectionView.register(UINib(nibName: "HeaderCell", bundle:nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderCell")
		collectionView.register(UINib(nibName: "HeaderCell", bundle:nil), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "HeaderCell")
		collectionView.register(UINib(nibName: "ExperienceCardCell", bundle:nil), forCellWithReuseIdentifier: "ExperienceCardCell")
	}
	
	func error(_ experience: String, error: Error)
	{
		
	}
	
	func experienceAt(_ indexPath: IndexPath) -> Experience?
	{
		if let items = groups[keys[indexPath.section]]
		{
			var experienceList : [Experience] = []
			for item in items
			{
				if let experience = experiences[item]
				{
					experienceList.append(experience)
				}
			}
			
			if sorted
			{
				experienceList.sort(by: { $0.name?.lowercased() < $1.name?.lowercased() })
			}
			
			if indexPath.item < experienceList.count
			{
				return experienceList[indexPath.item]
			}
		}
		return nil
	}
}
