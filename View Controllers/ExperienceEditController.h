//
//  ExperienceViewController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExperienceEditController : UITableViewController<UITextViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView* table;
}

@property ExperienceManager* experienceManager;
@property Experience* experience;

@end