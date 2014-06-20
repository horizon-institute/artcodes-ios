//
//  ACMarkerListController.swift
//  aestheticodes
//
//  Created by Kevin Glover on 09/06/2014.
//  Copyright (c) 2014 horizon. All rights reserved.
//

import Foundation
import UIKit

class ACMarkerListViewController : UITableViewController, UITextFieldDelegate
{
	var settings: ACMarkerSettings = ACMarkerSettings()
	
	@IBAction func done(AnyObject)
	{
		dismissViewControllerAnimated(true, nil)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		settings = ACMarkerSettings(file: "settings")
	}
	
	override func numberOfSectionsInTableView(UITableView) -> Int
	{
		return 3
	}

	override func shouldAutorotate() -> Bool
	{
		return false
	}
	
	override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
	{
		if(section == 0)
		{
			return settings.markers.count + 1
		}
		else
		{
			return 1
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject)
	{
		if (segue.identifier == "MarkerSegue")
		{
			let vc = segue.destinationViewController as ACMarkerViewController
			let tagIndex = (sender as UIButton).tag
	
			vc.settings = settings
		}
		else if (segue.identifier == "AddMarkerSegue")
		{
			let vc = segue.destinationViewController as ACMarkerViewController
			let tagIndex = (sender as UIButton).tag
			
			vc.settings = settings
		}
	}
	
	override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
	{
		if(indexPath.section == 0)
		{
			if(indexPath.row >= settings.markers.count)
			{
				return tableView.dequeueReusableCellWithIdentifier("AddMarkerPrototypeCell", forIndexPath: indexPath) as UITableViewCell
			}
			else
			{
				let cell = tableView.dequeueReusableCellWithIdentifier("MarkerPrototypeCell", forIndexPath: indexPath) as UITableViewCell

//				let code = settings.markers.objectAtIndex(indexPath.row)
//				cell.textLabel.text = "Marker \(code)"
//				cell.detailTextLabel.text = settings.markers[code]
//	
				return cell;
			}
		}
		else if(indexPath.section == 1)
		{
			return tableView.dequeueReusableCellWithIdentifier("SettingsPrototypeCell", forIndexPath: indexPath) as UITableViewCell;
		}
		return tableView.dequeueReusableCellWithIdentifier("AboutPrototypeCell", forIndexPath: indexPath) as UITableViewCell;
	}
	

//	-(void)updateDefaultUrlValueForKey:(NSString*)urlKey InTextField:(UITextField*)textField
//	{
//	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//	if ([textField.text length] > 0){
//	NSString* url = [self appendHttpScheme:textField.text];
//	if ([self validateUrl:url])
//	[userDefaults setObject:url forKey:urlKey];
//	else
//	{
//	[self displayMessage:NSLocalizedString(@"URL is not valid",nil)];
//	[textField becomeFirstResponder];
//	}
//	}
//	[userDefaults synchronize];
//	}
//	-(NSString*)appendHttpScheme:(NSString*)url
//	{
//	NSString* scheme = @"http://";
//	NSRange range = [url rangeOfString:scheme];
//	if (range.location == NSNotFound)
//	{
//	url = [NSString stringWithFormat:@"%@%@", scheme, url];
//	}
//	return url;
//	}
//	
//	-(void)displayMessage:(NSString*)msg
//	{
//	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Settings" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//	[alertView show];
//	}
//	
//	-(bool)validateUrl:(NSString*)url
//	{
//	
//	NSURL *validURL = [NSURL URLWithString:url];
//	if (validURL && validURL.scheme && validURL.host)
//	{
//	return true;
//	}
//	return false;
//	}
//	
//	-(BOOL)textFieldShouldReturn:(UITextField*)textField{
//	[textField resignFirstResponder];
//	return YES;
//	}
}