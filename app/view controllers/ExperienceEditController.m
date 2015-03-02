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
#import "ExperiencePropertyViewController.h"
#import "MarkerEditController.h"

#define NUMBER_OF_SECTIONS 4
#define NUMBER_OF_SETTINGS 5

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
	
	return [markers sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
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
		self.experience.name = textField.text;
		self.title = self.experience.name;
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
	[textView setBackgroundColor:[UIColor whiteColor]];
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
			[self performSegueWithIdentifier:@"PropertySegue" sender:@"minRegions"];
		}
		else if(indexPath.row == 1)
		{
			[self performSegueWithIdentifier:@"PropertySegue" sender:@"maxRegions"];
		}
		else if(indexPath.row == 2)
		{
			[self performSegueWithIdentifier:@"PropertySegue" sender:@"maxRegionValue"];
		}
		else if(indexPath.row == 3)
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
	self.title = self.experience.name;
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
		else
		{
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell" forIndexPath: indexPath];
			UILabel* label = (UILabel*)[cell.contentView viewWithTag:13];
			UITextField* field = (UITextField*)[cell.contentView viewWithTag:15];
			if(indexPath.row == 0)
			{
				label.text = @"Title";
				field.text = self.experience.name;
				field.tag = 1;
				field.delegate = self;
			}
			else if(indexPath.row == 1)
			{
				label.text = @"Icon";
				field.text = [self simplifyURL:self.experience.icon];
				field.keyboardType = UIKeyboardTypeURL;
				[field setTag:2];
				[field setDelegate:self];
			}
			else if(indexPath.row == 2)
			{
				[label setText:@"Image"];
				[field setText:[self simplifyURL:self.experience.image]];
				[field setKeyboardType:UIKeyboardTypeURL];
				[field setTag:3];
				[field setDelegate:self];
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
			
			NSString* code = [markerCodes objectAtIndex:indexPath.row];
			Marker* action = [self.experience getMarker:code];

			if(action.title)
			{
				cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", action.title, code];
			}
			else
			{
				cell.textLabel.text = [NSString stringWithFormat:@"Marker %@", code];
			}
			cell.detailTextLabel.text = [self simplifyURL:action.action];
			
			return cell;
		}
	}
	else if(indexPath.section == SETTINGS_SECTION)
	{
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:(indexPath.row!=4?@"PropertyCell":@"PropertySwitchCell") forIndexPath: indexPath];
		if(indexPath.row == 0)
		{
			[cell.textLabel setText:NSLocalizedString(@"minRegions", nil)];
			[cell.detailTextLabel setText:[NSString stringWithFormat:@"%d", self.experience.minRegions]];
		}
		else if(indexPath.row == 1)
		{
			[cell.textLabel setText:NSLocalizedString(@"maxRegions", nil)];
			[cell.detailTextLabel setText:[NSString stringWithFormat:@"%d", self.experience.maxRegions]];
		}
		else if(indexPath.row == 2)
		{
			[cell.textLabel setText:NSLocalizedString(@"maxRegionValue", nil)];
			[cell.detailTextLabel setText:[NSString stringWithFormat:@"%d", self.experience.maxRegionValue]];
		}
		else if(indexPath.row == 3)
		{
			[cell.textLabel setText:NSLocalizedString(@"checksumModulo", nil)];
			if(self.experience.checksumModulo == 1)
			{
				[cell.detailTextLabel setText:NSLocalizedString(@"checksumModulo_off", nil)];
			}
			else
			{
				[cell.detailTextLabel setText:[NSString stringWithFormat:@"%d", self.experience.checksumModulo]];
			}
		}
		else if(indexPath.row == 4)
		{
			[cell.textLabel setText:NSLocalizedString(@"embeddedChecksum", nil)];
			[cell.detailTextLabel setText:@""];
			UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
			cell.accessoryView = switchView;
			[switchView setOn:self.experience.embeddedChecksum animated:NO];
			[switchView addTarget:self action:@selector(embeddedChecksumSwitchChanged:) forControlEvents:UIControlEventValueChanged];
		}
		
		return cell;
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
