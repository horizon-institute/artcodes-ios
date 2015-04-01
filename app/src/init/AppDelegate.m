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
#import "AppDelegate.h"
#import <GooglePlus/GooglePlus.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (BOOL)application: (UIApplication *)application
			openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
		 annotation: (id)annotation
{
	NSLog(@"Handle URL: %@", url);
	if([url.scheme isEqualToString:@"file"])
	{
		if(self.manager != nil)
		{
			[self.manager loadExperience:url];
		}
	}
	else if([url.scheme isEqualToString:@"artcode"])
	{
		// TODO Start scan interface
	}

	return [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate
{
	return NO;
}

@end