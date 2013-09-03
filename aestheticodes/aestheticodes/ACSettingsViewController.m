//
//  ACSettingsViewController.m
//  aestheticodes
//
//  Created by horizon on 30/08/2013.
//  Copyright (c) 2013 horizon. All rights reserved.
//

#import "ACSettingsViewController.h"
#import "ACConstants.h"

@interface ACSettingsViewController ()

@end

@implementation ACSettingsViewController

@synthesize urlForCode1;
@synthesize urlForCode2;
@synthesize urlForCode3;
@synthesize urlForCode4;
@synthesize urlForCode5;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(IBAction)saveBtnClicked:(id)sender{
    [self updateDefaultUrlValueForKey:Code1 InTextField:self.urlForCode1];
    [self updateDefaultUrlValueForKey:Code2 InTextField:self.urlForCode2];
    [self updateDefaultUrlValueForKey:Code3 InTextField:self.urlForCode3];
    [self updateDefaultUrlValueForKey:Code4 InTextField:self.urlForCode4];
    [self updateDefaultUrlValueForKey:Code5 InTextField:self.urlForCode5];
    [self displayMessage:NSLocalizedString(@"Settings have been saved successfully", nil)];
    [self configureView];
}

-(void)updateDefaultUrlValueForKey:(NSString*)urlKey InTextField:(UITextField*)textField
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([textField.text length] > 0){
        NSString* url = [self appendHttpScheme:textField.text];
        if ([self validateUrl:url])
            [userDefaults setObject:url forKey:urlKey];
        else
        {
            [self displayMessage:NSLocalizedString(@"URL is not valid",nil)];
            [textField becomeFirstResponder];
        }
    }
    [userDefaults synchronize];
}

-(NSString*)appendHttpScheme:(NSString*)url{
    NSString* scheme = @"http://";
    NSRange range = [url rangeOfString:scheme];
    if (range.location == NSNotFound)
    {
        url = [NSString stringWithFormat:@"%@%@", scheme, url];
    }
    return url;
}

-(void)displayMessage:(NSString*)msg
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Settings" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

-(bool)validateUrl:(NSString*)url
{
    
    NSURL *validURL = [NSURL URLWithString:url];
    if (validURL && validURL.scheme && validURL.host)
    {
       return true;
    }
    return false;
}

-(IBAction)resetBtnClicked:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:defaultUrl forKey:Code1];
    [userDefaults setObject:defaultUrl forKey:Code2];
    [userDefaults setObject:defaultUrl forKey:Code3];
    [userDefaults setObject:defaultUrl forKey:Code4];
    [userDefaults setObject:defaultUrl forKey:Code5];
    [userDefaults synchronize];
    [self configureView];
}

-(void)configureView
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [self.urlForCode1 setText:[userDefaults objectForKey:Code1]];
    [self.urlForCode2 setText:[userDefaults objectForKey:Code2]];
    [self.urlForCode3 setText:[userDefaults objectForKey:Code3]];
    [self.urlForCode4 setText:[userDefaults objectForKey:Code4]];
    [self.urlForCode5 setText:[userDefaults objectForKey:Code5]];
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
    [textField resignFirstResponder];
    return YES;
}

@end
