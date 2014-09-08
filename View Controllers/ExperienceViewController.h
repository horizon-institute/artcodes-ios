//
//  ExperienceViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExperienceViewController : UITableViewController {
	IBOutlet UITableView* table;
}

@property Experience* experience;

@end