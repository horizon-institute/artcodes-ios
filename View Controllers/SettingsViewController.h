//
//  SettingsViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController {
	IBOutlet UITextField* minRegions;
	IBOutlet UITextField* maxRegions;
	IBOutlet UITextField* maxRegionValue;
	IBOutlet UITextField* maxEmptyRegions;
	
	IBOutlet UITextField* validationRegions;
	IBOutlet UITextField* validationRegionValue;
	IBOutlet UITextField* checksum;
}

@property Experience* experience;

@end