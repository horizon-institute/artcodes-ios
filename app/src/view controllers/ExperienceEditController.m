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
#import "ExperienceManager.h"
#import "ExperienceEditController.h"
#import "RegionViewController.h"
#import "ExperiencePropertyViewController.h"
#import "MarkerEditController.h"

#define NUMBER_OF_SECTIONS 4
#define NUMBER_OF_SETTINGS 4

#define DETAILS_SECTION 0
#define MARKERS_SECTION 1
#define SETTINGS_SECTION 2
#define DELETE_BUTTON_SECTION 3

@interface ExperienceEditController ()
@property UITextView* descriptionView;
@property NSString* error;
@end

@implementation ExperienceEditController

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(NSArray*) getMarkerCodes
{
	NSMutableArray* markers = [[NSMutableArray alloc] init];
	for (Marker* action in self.experience.markers)
	{
		[markers addObject:action.code];
	}

	return [markers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
	{
		if ([obj1 length] > [obj2 length])
		{
			return NSOrderedDescending;
		}
		else if([obj1 length] < [obj2 length])
		{
			return NSOrderedAscending;
		}
		else
		{
			return [obj1 caseInsensitiveCompare:obj2];
		}
	}];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return NUMBER_OF_SECTIONS;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.estimatedRowHeight = 44.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
	self.experience.description = textView.text;

	if ([textView.text length] > 0)
	{
		textView.backgroundColor = [UIColor whiteColor];
	}
	else
	{
		textView.backgroundColor = [UIColor clearColor];
	}
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
	textField.backgroundColor = [UIColor whiteColor];
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
	NSString* urlRegEx = @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
	if (textField.text.length > 0)
	{
		textField.backgroundColor = [UIColor whiteColor];
	}
	else
	{
		textField.backgroundColor = [UIColor clearColor];
	}

	if(textField.tag == 1)
	{
		self.experience.name = textField.text;
		//self.title = self.experience.name;
	}
	else if(textField.tag == 2)
	{
		NSString* url = [self unsimplifyURL:textField.text];
		if(url == nil || [url rangeOfString:urlRegEx options:NSRegularExpressionSearch].location != NSNotFound)
		{
			textField.rightViewMode = UITextFieldViewModeNever;
			self.experience.icon = url;
		}
		else
		{
			textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_warning"]];
			self.error = @"Icon is not a valid URL";
			textField.rightViewMode = UITextFieldViewModeAlways;
		}
	}
	else if(textField.tag == 3)
	{
		NSString* url = [self unsimplifyURL:textField.text];
		if(url == nil || [url rangeOfString:urlRegEx options:NSRegularExpressionSearch].location != NSNotFound)
		{
			textField.rightViewMode = UITextFieldViewModeNever;
			self.experience.image = url;
		}
		else
		{
			textField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_warning"]];
			self.error = @"Image is not a valid URL";
			textField.rightViewMode = UITextFieldViewModeAlways;
		}
	}
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	textView.backgroundColor = [UIColor whiteColor];
	return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == DETAILS_SECTION)
	{
		return 4;
	}
	else if(section == MARKERS_SECTION)
	{
		NSArray* markers = [self getMarkerCodes];
		return [markers count] + 1;
	}
	else if(section == SETTINGS_SECTION)
	{
		return NUMBER_OF_SETTINGS;
	}
	else if(section == DELETE_BUTTON_SECTION)
	{
		return 1;
	}
	return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == DETAILS_SECTION && indexPath.row == 3)
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
		textView.text = self.experience.description;
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
	}

	if(indexPath.section == SETTINGS_SECTION)
	{
		if(indexPath.row == 0)
		{
			[self performSegueWithIdentifier:@"RegionSegue" sender:@"minRegions"];
		}
		else if(indexPath.row == 1)
		{
			[self performSegueWithIdentifier:@"PropertySegue" sender:@"maxRegionValue"];
		}
		else if(indexPath.row == 2)
		{
			[self performSegueWithIdentifier:@"PropertySegue" sender:@"checksumModulo"];
		}
	}
}

-(IBAction)done:(UIBarButtonItem*)sender
{
	[self.view endEditing:YES];
	if(self.experience.op == nil)
	{
		self.experience.op = @"update";
	}
	[self.experienceManager add:self.experience];
	[self.experienceManager save];
	[self.experienceManager update];
	[self.navigationController popViewControllerAnimated:true];
}

-(IBAction)cancel:(UIBarButtonItem*)sender
{
	[self.experienceManager load];
	[self.navigationController popViewControllerAnimated:true];
}

-(BOOL)shouldAutorotate
{
	return false;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	//self.title = self.experience.name;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[table reloadData];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if([segue.identifier isEqual:@"EditMarkerSegue"])
	{
		MarkerEditController *vc = [segue destinationViewController];
		long index = [table indexPathForCell:sender].row;
		NSString* code = [[self getMarkerCodes] objectAtIndex:index];
		vc.experience = self.experience;
		for(Marker* action in self.experience.markers)
		{
			if([action.code isEqual:code])
			{
				vc.marker = action;
			}
		}
	}
	else if([segue.identifier isEqual:@"AddMarkerSegue"])
	{
		MarkerEditController *vc = [segue destinationViewController];
		vc.experience = self.experience;
		vc.marker = [[Marker alloc] init];
		vc.marker.code = [self.experience getNextUnusedMarker];
	}
	else if([segue.identifier isEqual:@"PropertySegue"])
	{
		ExperiencePropertyViewController *vc = [segue destinationViewController];
		vc.experience = self.experience;
		vc.property = sender;
	}
	else if([segue.identifier isEqual:@"RegionSegue"])
	{
		RegionViewController *vc = [segue destinationViewController];
		vc.experience = self.experience;
	}
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField
{
	BOOL didResign = [textField resignFirstResponder];
	if (!didResign)
	{
		return NO;
	}

	UIView* view = textField;
	while(view != nil)
	{
		view = view.superview;
		if([view isKindOfClass:[UITableViewCell class]])
		{
			UITableViewCell* cell = (UITableViewCell*)view;
			NSIndexPath* path = [self.tableView indexPathForCell:cell];
			NSInteger sections = [self numberOfSectionsInTableView:[self tableView]];

			while(true)
			{
				NSInteger rows = [self tableView:[self tableView] numberOfRowsInSection:path.section];
				NSInteger row = path.row + 1;
				NSInteger section = path.section;
				if(path.row >= rows)
				{
					row = 0;
					section = path.section + 1;
					if(section >= sections)
					{
						break;
					}
				}

				path = [NSIndexPath indexPathForRow:row inSection:section];
				UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:path];
				if(cell != nil)
				{
					UIView* view = cell.contentView;
					for(UIView* subview in view.subviews)
					{
						if([subview isKindOfClass:[UITextView class]])
						{
							[subview becomeFirstResponder];
							return YES;
						}
						else if([subview isKindOfClass:[UITextField class]])
						{
							[subview becomeFirstResponder];
							return YES;
						}
					}
				}
			}

			break;
		}
	}

	return YES;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* markerCodes = [self getMarkerCodes];
	if(indexPath.section == DETAILS_SECTION)
	{
		if(indexPath.row == 3)
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DescriptionCell" forIndexPath: indexPath];
			for(UIView* subview in cell.contentView.subviews)
			{
				if([subview isKindOfClass:[UITextView class]])
				{
					self.descriptionView = (UITextView*) subview;
				}
			}
			self.descriptionView.delegate = self;
			self.descriptionView.text = self.experience.description;
			if(self.experience.description == nil)
			{
				self.descriptionView.backgroundColor = [UIColor clearColor];
			}
			else
			{
				self.descriptionView.backgroundColor = [UIColor whiteColor];
			}
			[self.descriptionView sizeToFit];

			return cell;
		}
		else if(indexPath.row == 0)
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TitleEditCell" forIndexPath: indexPath];
			UITextField* field = (UITextField*)[cell.contentView viewWithTag:25];
			field.text = self.experience.name;
			field.tag = 1;
			field.delegate = self;
			if (field.text.length > 0)
			{
				field.backgroundColor = [UIColor whiteColor];
			}
			else
			{
				field.backgroundColor = [UIColor clearColor];
			}
			return cell;
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"IconEditCell" forIndexPath: indexPath];
			UILabel* label = (UILabel*)[cell.contentView viewWithTag:23];
			UITextField* field = (UITextField*)[cell.contentView viewWithTag:25];
			if(indexPath.row == 1)
			{
				label.text = @"Icon";
				field.text = [self simplifyURL:self.experience.icon];
				field.tag = 2;
			}
			else if(indexPath.row == 2)
			{
				label.text = @"Image";
				field.text = [self simplifyURL:self.experience.image];
				field.tag = 3;
			}

			field.delegate = self;
			if (field.text.length > 0)
			{
				field.backgroundColor = [UIColor whiteColor];
			}
			else
			{
				field.backgroundColor = [UIColor clearColor];
			}

			return cell;
		}
	}
	else if(indexPath.section == MARKERS_SECTION)
	{
		if(indexPath.row >= markerCodes.count)
		{
			return [tableView dequeueReusableCellWithIdentifier:@"AddMarkerCell" forIndexPath:indexPath];
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EditMarkerCell" forIndexPath: indexPath];
			UILabel* label = (UILabel*)[cell.contentView viewWithTag:23];
			UILabel* detailLabel = (UILabel*)[cell.contentView viewWithTag:27];

			NSString* code = [markerCodes objectAtIndex:indexPath.row];
			Marker* action = [self.experience getMarker:code];

			if(action.title)
			{
				label.text = [NSString stringWithFormat:@"Marker %@   %@", code, action.title];
			}
			else
			{
				label.text = [NSString stringWithFormat:@"Marker %@", code];
			}
			detailLabel.text = [self simplifyURL:action.action];

			return cell;
		}
	}
	else if(indexPath.section == SETTINGS_SECTION)
	{
		if(indexPath.row == 3)
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PropertySwitchCell" forIndexPath: indexPath];
			UILabel* label = (UILabel*)[cell.contentView viewWithTag:23];
			UISwitch* switchView = (UISwitch*)[cell.contentView viewWithTag:29];
			
			label.text = NSLocalizedString(@"embeddedChecksum", nil);
			[switchView setOn:self.experience.embeddedChecksum animated:NO];
			[switchView addTarget:self action:@selector(embeddedChecksumSwitchChanged:) forControlEvents:UIControlEventValueChanged];
			
			return cell;
		}
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"PropertyCell" forIndexPath: indexPath];
			UILabel* label = (UILabel*)[cell.contentView viewWithTag:23];
			UILabel* detailLabel = (UILabel*)[cell.contentView viewWithTag:27];
			
			if(indexPath.row == 0)
			{
				label.text = NSLocalizedString(@"regions", nil);
				if(self.experience.maxRegions == self.experience.minRegions)
				{
					detailLabel.text = [NSString stringWithFormat:@"%d", self.experience.minRegions];
				}
				else
				{
					detailLabel.text = [NSString stringWithFormat:@"%d-%d", self.experience.minRegions, self.experience.maxRegions];
				}
			}
			else if(indexPath.row == 1)
			{
				label.text = NSLocalizedString(@"maxRegionValue", nil);
				detailLabel.text = [NSString stringWithFormat:@"%d", self.experience.maxRegionValue];
			}
			else if(indexPath.row == 2)
			{
				label.text = NSLocalizedString(@"checksumModulo", nil);
				if(self.experience.checksumModulo == 1)
				{
					detailLabel.text = NSLocalizedString(@"checksumModulo_off", nil);
				}
				else
				{
					detailLabel.text = [NSString stringWithFormat:@"%d", self.experience.checksumModulo];
				}
			}
			
			return cell;
		}
	}
	else if(indexPath.section == DELETE_BUTTON_SECTION)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DeleteCell" forIndexPath: indexPath];
		return cell;
	}
	return nil;
}

-(void)embeddedChecksumSwitchChanged:(id)sender
{
	UISwitch* embeddedChecksumSwitch = (UISwitch*) sender;
	self.experience.embeddedChecksum = embeddedChecksumSwitch.on;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 1:
			self.experience.op = @"remove";
			[self done:nil];
			break;
		default:
			NSLog(@"Delete was cancelled by the user");
	}
}

-(IBAction)deleteItem:(id)sender
{
	UIAlertView* alert = [[UIAlertView alloc] init];
	alert.title = @"Confirm Delete";
	alert.message = @"Are you sure you want to delete this?";
	alert.delegate = self;
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Delete"];
	[alert show];
}
@end
