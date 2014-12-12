//
//  ExperienceListViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ECSlidingViewController.h"
#import "ExperienceManager.h"
#import <UIKit/UIKit.h>

@interface ExperienceSelectionViewController : UITableViewController<UIAlertViewDelegate> {
	IBOutlet UITableView* table;
}

@property (weak) ExperienceManager* experienceManager;

@end