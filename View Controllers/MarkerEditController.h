//
//  MarkerActionEditController.h
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Marker.h"

@interface MarkerEditController : UITableViewController<UITextViewDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
	IBOutlet UITableView* table;
}

@property Experience* experience;
@property Marker* marker;

@end
