/*
 * Artcodes recognises a different marker scheme that allows the
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

import UIKit
import ArtcodesScanner
import DrawerController
import UIColor_Hex_Swift

@UIApplicationMain
class ArtcodeAppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate
{
	static let googleChromeHTTPScheme: String = "googlechrome:"
	static let googleChromeHTTPSScheme: String = "googlechromes:"
	
	static func chromifyURL(url: String) -> NSURL?
	{
		var alteredURL = url
		if alteredURL.hasPrefix("http://")
		{
			alteredURL = alteredURL.stringByReplacingOccurrencesOfString("http://", withString: googleChromeHTTPScheme)
		}
		else if alteredURL.hasPrefix("https://")
		{
			alteredURL = alteredURL.stringByReplacingOccurrencesOfString("https://", withString: googleChromeHTTPSScheme)
		}
		return NSURL(string: alteredURL)
	}
	
	static let imageCache = NSCache()
	var navigationController: UINavigationController!
	let server = AppEngineServer()
	var drawerController: DrawerController!
	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
	{
		// Configure tracker from GoogleService-Info.plist.
		var configureError:NSError?
		GGLContext.sharedInstance().configureWithError(&configureError)
		assert(configureError == nil, "Error configuring Google services: \(configureError)")
		
		// Optional: configure GAI options.
		let gai = GAI.sharedInstance()
		gai.trackUncaughtExceptions = true
		#if DEBUG
            NSLog("Debugging")
			gai.logger.logLevel = GAILogLevel.Verbose
			gai.dryRun = true
		#endif
		
		let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
		NSURLCache.setSharedURLCache(URLCache)
		
		GIDSignIn.sharedInstance().delegate = self
		GIDSignIn.sharedInstance().signInSilently()
		
		if let path = NSBundle.mainBundle().pathForResource("GoogleService-Info", ofType: "plist")
		{
			if let dict = NSDictionary(contentsOfFile: path)
			{
				if let apiKey = dict["API_KEY"] as? String
				{
					// GGLContext seems to support configuring maps
					// No documentation yet though...
					NSLog("API Key provided \(apiKey)")
					GMSServices.provideAPIKey(apiKey)
				}
			}
		}
		
		UIApplication.sharedApplication().statusBarStyle = .LightContent
		
		navigationController = UINavigationController()
		navigationController.navigationBar.translucent = false
		navigationController.navigationBar.tintColor = UIColor.whiteColor()
		navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
		navigationController.navigationBar.barTintColor = UIColor(rgba: "#295a9e")
		//navigationController.navigationBar.shadowImage = UIImage()
	
		UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_18pt")
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_18pt")
		
		let menuController = NavigationMenuViewController()	
		drawerController = DrawerController(centerViewController: RecommendedViewController(), leftDrawerViewController: menuController)
		drawerController.maximumRightDrawerWidth = 200.0
		drawerController.openDrawerGestureModeMask = .All
		drawerController.closeDrawerGestureModeMask = .All
		drawerController.title = NSLocalizedString("recommended", tableName: nil, bundle: NSBundle.mainBundle(), value: "Recommended", comment: "")
		drawerController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_menu_18pt"), style: .Plain, target: self, action: "toggleMenu")
		
   		menuController.drawerController = drawerController
        
		navigationController.pushViewController(drawerController, animated: false)
		
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		if let window = window
		{
			window.backgroundColor = UIColor.whiteColor()
			window.rootViewController = navigationController
			window.makeKeyAndVisible()
		}
		
		return true
	}
	
	func toggleMenu()
	{
		drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
	}
	
	func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!)
	{
		if (error == nil)
		{
			NSLog("Signed in as \(user.profile.name) (\(user.userID))")
			let account = AppEngineAccount(email: user.profile.email, name: user.profile.name, token: user.authentication.accessToken)
            server.accounts[account.id] = account
			if drawerController != nil
			{
            if let menuController = drawerController.leftDrawerViewController as? NavigationMenuViewController
            {
                menuController.tableView.reloadData()
            }
			}
		}
		else
		{
			NSLog("Sign in error: \(error.localizedDescription)")
//			for account in server.accounts
//			{
//				if let googleAccount = account as? AppEngineAccount
//				{
//					// TODO Remove?
//					if let menuController = drawerController.leftDrawerViewController as? NavigationMenuViewController
//					{
//						menuController.tableView.reloadData()
//					}
//				}
//			}
		}
	}
	
	func signIn(signIn: GIDSignIn!, didDisconnectWithUser user:GIDGoogleUser!, withError error: NSError!)
	{
        NSLog("Disconnected")
	}
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool
	{
		let handled = GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation)
		if !handled
		{
			if url.scheme == "x-scan-artcode"
			{
				// TODO open scanning view controller
			}
			else
			{
				server.loadExperience(url.absoluteString) { (experience) -> Void in
					NSLog("Loaded \(url): \(experience.json)")
					self.navigationController.pushViewController(ExperienceViewController(experience: experience), animated: false)
				}
			}
		}
		
		return handled
	}

	func applicationWillResignActive(application: UIApplication)
	{
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication)
	{
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication)
	{
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication)
	{
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

