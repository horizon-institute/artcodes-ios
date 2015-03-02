/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2015  Aestheticodes
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import "Marker.h"
#import "Experience.h"
#import "MarkerEditController.h"

@interface MarkerEditController ()
@property UITextView* descriptionView;
@end

@implementation MarkerEditController
@synthesize marker;

#pragma mark - Table view data source

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	UIView* view = cell.contentView;
	for(UIView* subview in view.subviews)
	{
		if([subview isKindOfClass:[UITextView class]])
		{
			[subview becomeFirstResponder];
		}
		else if([subview isKindOfClass:[UITextField class]])
		{
			[subview becomeFirstResponder];
		}
		else if([subview isKindOfClass:[UIButton class]])
		{
			[(UIButton*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
		else if([subview isKindOfClass:[UISwitch class]])
		{
			[(UISwitch*)subview sendActionsForControlEvents:UIControlEventTouchUpInside];
		}
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 2 && indexPath.row == 1)
	{
		return [self textViewHeightForRowAtIndexPath:self.descriptionView];
	}
	return 44;
}

- (CGFloat)textViewHeightForRowAtIndexPath: (UITextView*)textView
{
	CGFloat textViewWidth = 0;
	if(textView == nil)
	{
		textView = [[UITextView alloc] init];
		textView.text = self.marker.description;
		textView.font = [UIFont systemFontOfSize:14];
		textViewWidth = [[UIScreen mainScreen] bounds].size.width - 24;
	}
	else
	{
		textViewWidth = textView.frame.size.width;
	}
	
	CGSize size = [textView sizeThatFits:CGSizeMake(textViewWidth, FLT_MAX)];
	return size.height + 11;
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	[textView setBackgroundColor:[UIColor whiteColor]];
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(self.marker.showDetail)
	{
		return 4;
	}
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return 3;
	}
	else if(section == 1)
	{
		return 1;
	}
	else if(section == 2 && self.marker.showDetail)
	{
		return 2;
	}
	return 1;
}

-(void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	if(self.marker != nil)
	{
		for(Marker* aMarker in self.experience.markers)
		{
			if([aMarker.code isEqualToString:self.marker.code])
			{
				[self.experience.markers removeObject:aMarker];
				break;
			}
		}
		[self.experience.markers addObject:self.marker];
	}
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.title = [NSString stringWithFormat:@"Marker %@", self.marker.code];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell" forIndexPath: indexPath];
		UILabel* label;
		UITextField* field;
		for(UIView* subview in cell.contentView.subviews)
		{
			if([subview isKindOfClass:[UITextField class]])
			{
				field = (UITextField*) subview;
			}
			else if([subview isKindOfClass:[UILabel class]])
			{
				label = (UILabel*) subview;
			}
		}
		if(indexPath.row == 0)
		{
			[label setText:@"Title"];
			[field setText:self.marker.title];
			[field setTag:3];
			[field setDelegate:self];
		}
		else if(indexPath.row == 1)
		{
			[label setText:@"Code"];
			[field setText:self.marker.code];
			[field setTag:1];
			[field setDelegate:self];
			[field setEnabled:![self.experience.markers containsObject:self.marker.code]];
		}
		else if(indexPath.row == 2)
		{
			[label setText:@"URL"];
			[field setText:[self simplifyURL:self.marker.action]];
			[field setKeyboardType:UIKeyboardTypeURL];
			[field setTag:2];
			[field setDelegate:self];
		}
		return cell;
	}
	else if(indexPath.section == 1)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DetailCell" forIndexPath: indexPath];
		for(UIView* subview in cell.contentView.subviews)
		{
			if([subview isKindOfClass:[UISwitch class]])
			{
				UISwitch* uiswitch = (UISwitch*) subview;
				uiswitch.on = self.marker.showDetail;
			}
		}
		return cell;
	}
	else if(indexPath.section == 2 && self.marker.showDetail)
	{
		if(indexPath.row == 1)
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionCell" forIndexPath: indexPath];
			for(UIView* subview in cell.contentView.subviews)
			{
				if([subview isKindOfClass:[UITextView class]])
				{
					self.descriptionView = (UITextView*) subview;
					self.descriptionView.delegate = self;
					self.descriptionView.text = self.marker.description;
					if(self.marker.description == nil)
					{
						self.descriptionView.backgroundColor = [UIColor clearColor];
					}
					else
					{
						self.descriptionView.backgroundColor = [UIColor whiteColor];
					}
					[self.descriptionView sizeToFit];
				}
			}
			return cell;
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell" forIndexPath: indexPath];
			UILabel* label;
			UITextField* field;
			for(UIView* subview in cell.contentView.subviews)
			{
				if([subview isKindOfClass:[UITextField class]])
				{
					field = (UITextField*) subview;
				}
				else if([subview isKindOfClass:[UILabel class]])
				{
					label = (UILabel*) subview;
				}
			}
			if(indexPath.row == 0)
			{
				[label setText:@"Image"];
				[field setText:[self simplifyURL:self.marker.image]];
				[field setKeyboardType:UIKeyboardTypeURL];
				[field setTag:4];
				[field setDelegate:self];
			}
			return cell;
		}
	}
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DeleteCell" forIndexPath: indexPath];
	return cell;
}

-(NSString*)simplifyURL:(NSString*)url
{
	NSString* prefix = @"http://";
	if(url != nil && [url hasPrefix:prefix])
	{
		NSRange range = NSMakeRange(prefix.length, url.length - prefix.length);
		return [url substringWithRange:range];
	}
	return url;
}

-(NSString*)unsimplifyURL:(NSString*)url
{
	NSString* schema = @"://";
	if(url == nil || url.length == 0)
	{
		return nil;
	}
	
	if([url rangeOfString:schema].location == NSNotFound)
	{
		return [NSString stringWithFormat:@"http://%@", url];
	}
	return url;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
	self.marker.description = textView.text;
	
	if ([textView.text length] > 0)
	{
		[textView setBackgroundColor:[UIColor whiteColor]];
	}
	else
	{
		[textView setBackgroundColor:[UIColor clearColor]];
	}
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
	NSString* urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
	if(textField.tag == 1)
	{
		NSMutableString *error = [[NSMutableString alloc] init];
		if([self.experience isKeyValid: textField.text reason:error])
		{
			self.marker.code = textField.text;
			self.title = [NSString stringWithFormat:@"Marker %@", self.marker.code];
			textField.rightViewMode = UITextFieldViewModeNever;
		}
		else
		{
			textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_warning"]];
			textField.rightViewMode = UITextFieldViewModeAlways;
		}
		[table reloadData];
	}
	else if(textField.tag == 2)
	{
		NSString* url = [self unsimplifyURL:textField.text];
		if(url == nil || [url rangeOfString:urlRegEx options:NSRegularExpressionSearch].location != NSNotFound)
		{
			textField.rightViewMode = UITextFieldViewModeNever;
			self.marker.action = url;
		}
		else
		{
			textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_warning"]];
			textField.rightViewMode = UITextFieldViewModeAlways;
		}
	}
	else if(textField.tag == 3)
	{
		NSString *trimmedString = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if(trimmedString.length == 0)
		{
			self.marker.title = nil;
		}
		else
		{
			self.marker.title = textField.text;
		}
	}
	else if(textField.tag == 4)
	{
		NSString* url = [self unsimplifyURL:textField.text];
		if(url == nil || [url rangeOfString:urlRegEx options:NSRegularExpressionSearch].location != NSNotFound)
		{
			textField.rightViewMode = UITextFieldViewModeNever;
			self.marker.image = url;
		}
		else
		{
			textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_warning"]];
			textField.rightViewMode = UITextFieldViewModeAlways;
		}
	}
}

-(IBAction)showDetailSwitch:(id)sender
{
	UISwitch* uiswitch = sender;
	self.marker.showDetail = uiswitch.on;
	[table reloadData];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 1:
			[self.experience.markers removeObject:marker];
			self.marker = nil;
			[self.navigationController popViewControllerAnimated:true];
			break;
		default:
			NSLog(@"Delete was cancelled by the user");
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
}

-(IBAction)deleteItem:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Confirm Delete";
	alert.message = @"Are you sure you want to delete this marker?";
	alert.delegate = self;
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Delete"];
	[alert show];
}
@end

