//
//  ACSettingsViewController.h
//  aestheticodes
//
//  Created by horizon on 30/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACSettingsViewController : UITableViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *urlForCode1;
@property (weak, nonatomic) IBOutlet UITextField *urlForCode2;
@property (weak, nonatomic) IBOutlet UITextField *urlForCode3;
@property (weak, nonatomic) IBOutlet UITextField *urlForCode4;
@property (weak, nonatomic) IBOutlet UITextField *urlForCode5;

-(IBAction)saveBtnClicked:(id)sender;
-(IBAction)resetBtnClicked:(id)sender;
-(IBAction)aboutBtnClicked:(id)sender;

@end
