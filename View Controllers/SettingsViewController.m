//
//  SettingsViewController.m
//  aestheticodes
//
//  Created by Kevin Glover on 03/07/2014.
//  Copyright (c) 2014 Horizon. All rights reserved.
//

#import "Experience.h"
#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self loadValues];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	UIView* view = [cell contentView];
	for (UIView* subview in [view subviews])
	{
		if([subview isKindOfClass:[UITextField class]])
		{
			[subview becomeFirstResponder];
		}
	}
}

-(void)loadValues
{
	self.title = [NSString stringWithFormat:@"%@ Settings", self.experience.name];
	
	minRegions.text = [NSString stringWithFormat:@"%d", self.experience.minRegions];
	maxRegions.text = [NSString stringWithFormat:@"%d", self.experience.maxRegions];
	maxRegionValue.text = [NSString stringWithFormat:@"%d", self.experience.maxRegionValue];
	maxEmptyRegions.text = [NSString stringWithFormat:@"%d", self.experience.maxEmptyRegions];

	validationRegions.text = [NSString stringWithFormat:@"%d", self.experience.validationRegions];
	validationRegionValue.text = [NSString stringWithFormat:@"%d", self.experience.validationRegionValue];
	checksum.text = [NSString stringWithFormat:@"%d", self.experience.checksumModulo];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self saveValues];
}

-(IBAction)validate:(UITextField*)sender
{
	[self isValid:sender];
}

-(BOOL)isValid:(UITextField*)sender
{
	bool valid = true;
	if(![self isInt:sender.text])
	{
		valid = false;
	}
	NSInteger value = [sender.text integerValue];
	if(value < 0 || value > 20)
	{
		valid = false;
	}
	
	if(sender == minRegions || sender == maxRegions)
	{
		if([self isInt:minRegions.text] && [self isInt:maxRegions.text])
		{
			NSInteger minValue = [minRegions.text integerValue];
			NSInteger maxValue = [maxRegions.text integerValue];
			if(minValue > maxValue)
			{
				valid = false;
			}
		}
	}
	
	if(valid)
	{
		sender.rightViewMode = UITextFieldViewModeNever;
	}
	else
	{
		sender.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error.png"]];
		sender.rightViewMode = UITextFieldViewModeAlways;
	}
	
	return valid;
}

-(bool)isInt:(NSString*)string
{
	NSInteger value = [string integerValue];
	if(value != 0)
	{
		return true;
	}
	return [string isEqualToString:@"0"];
}

-(void)saveValue:(UITextField*)sender
{
	if([self isValid:sender])
	{
		[self.experience setIntValue:[sender.text integerValue] key:sender.restorationIdentifier];
	}
}

-(void)saveValues
{
	[self saveValue:minRegions];
	[self saveValue:maxRegions];
	[self saveValue:maxRegionValue];
	[self saveValue:maxEmptyRegions];

	[self saveValue:validationRegions];
	[self saveValue:validationRegionValue];
	
	[self saveValue:checksum];	
}

@end
