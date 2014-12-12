//
//  ExperienceListViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/09/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "ECSlidingViewController.h"
#import "ExperienceManager.h"
#import "ExperienceDelegate.h"
#import <UIKit/UIKit.h>

@interface ExperienceListViewController : UITableViewController<ExperienceDelegate> {
	IBOutlet UITableView* table;
}

@property (weak) ExperienceManager* experienceManager;

@end