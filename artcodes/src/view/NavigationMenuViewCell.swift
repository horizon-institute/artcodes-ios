//
//  ExperienceItemView.swift
//  artcodes
//
//  Created by Kevin Glover on 04/08/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import UIKit
import artcodesScanner

class NavigationMenuViewCell: UITableViewCell
{
	@IBOutlet weak var navigationIcon: UIImageView!
	@IBOutlet weak var navigationTitle: UILabel!
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init(coder: aDecoder)
		selectionStyle = .None
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String!)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		selectionStyle = .None
	}
	
	override func setSelected(selected: Bool, animated: Bool)
	{
		super.setSelected(selected, animated: animated)
		if selected
		{
			navigationIcon.tintColor = UIColor(rgba: "#194a8e")
			navigationTitle.textColor = UIColor(rgba: "#194a8e")
		}
		else
		{
			navigationIcon.tintColor = UIColor.blackColor()
			navigationTitle.textColor = UIColor.blackColor()
		}
	}
}
