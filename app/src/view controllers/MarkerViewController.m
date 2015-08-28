/*
 * Aestheticodes recognises a different marker scheme that allows the
 * creation of aesthetically pleasing, even beautiful, codes.
 * Copyright (C) 2013-2015  The University of Nottingham
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
#import "MarkerViewController.h"
#import "OpenInChromeController.h"

@interface MarkerViewController ()
@end

@implementation MarkerViewController

@synthesize webView;
@synthesize action;

- (void)viewWillAppear: (BOOL)animated
{
	[super viewWillAppear: animated];
	
	if (action != nil)
	{
		NSString* title;
		if(action.title)
		{
			title = [NSString stringWithFormat:action.title, action.code];
		}
		else
		{
			title = [NSString stringWithFormat:@"Marker %@", action.code];
		}
		
		self.title = title;
		self.navigationController.title = self.title;
		
		if(action.showDetail)
		{
			NSString* description;
			if(action.description)
			{
				description = action.description;
			}
			else if (action.action)
			{
				description = action.action;
			}
			
			NSString* actionURL = action.action;
			
			NSString* image;
			if (action.image)
			{
				image = action.image;
			}
			else
			{
				image = @"penguins.png";
			}
			
			NSError* error = nil;
			NSString *path = [[NSBundle mainBundle] pathForResource: @"marker" ofType: @"html"];
			NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
			
			NSString* html = [NSString stringWithFormat: res, image, title, actionURL, description];
			
			NSLog(@"%@", html);
			
			[webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
		}
		else
		{
			[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:action.action]]];
		}
	}
	else if (self.experience != nil)
	{
		// load "about" screen
		self.title = @"About";
		[self.navigationController setTitle:self.title];
		
		NSError* error = nil;
		NSString *path = [[NSBundle mainBundle] pathForResource: @"about" ofType: @"html"];
		NSString *res = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
		NSString* html = [NSString stringWithFormat: res, self.experience.image, self.experience.name, self.experience.description];
		[webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
	}
	
	[super viewDidLoad];
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
	// change experience if specific link is sent
	NSError *error;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(http://)?(www\\.)?aestheticodes\\.com/changeToExperience/(.*)$" options:NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:[inRequest.URL absoluteString] options:0 range:NSMakeRange(0, [inRequest.URL absoluteString].length)];
	if ([matches count] > 0)
	{
		NSString *experienceId = [[inRequest.URL absoluteString] substringWithRange:[matches[0] rangeAtIndex:3]];
		Experience * experienceToChangeTo = [self.experienceManager getExperience:experienceId];
		
		if (experienceToChangeTo != nil)
		{
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			[userDefaults setObject:experienceToChangeTo.id forKey:@"experience"];
			[userDefaults synchronize];
			NSLog(@"Selected %@", experienceToChangeTo.id);
			self.experienceController.item = experienceToChangeTo;
		}
		return NO;
	}
	
	return YES;
}

- (IBAction)openInBrowser:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:action.action]];
}
@end
