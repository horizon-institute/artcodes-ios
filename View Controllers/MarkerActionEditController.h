//
//  MarkerActionEditController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MarkerAction.h"

@interface MarkerActionEditController : UITableViewController<UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UIBarButtonItem* doneButton;
	IBOutlet UITableView* table;
	IBOutlet UITextField* codeView;
	IBOutlet UITextField* urlView;
}

@property MarkerAction* action;

@end
