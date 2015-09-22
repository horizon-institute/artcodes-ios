//
//  AppDelegate.swift
//  artcodes
//
//  Created by Kevin Glover on 31/07/2015.
//  Copyright (c) 2015 Horizon. All rights reserved.
//

import UIKit
import artcodesScanner
import DrawerController
import UIColor_Hex_Swift

@UIApplicationMain
class ArtcodeAppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate
{
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
            NSLog("DEBUGGING!")
			gai.logger.logLevel = GAILogLevel.Verbose
			gai.dryRun = true
		#endif
		
		GIDSignIn.sharedInstance().delegate = self
		GIDSignIn.sharedInstance().signInSilently()

		UIApplication.sharedApplication().statusBarStyle = .LightContent
		
		navigationController = UINavigationController()
		navigationController.navigationBar.translucent = false
		navigationController.navigationBar.tintColor = UIColor.whiteColor()
		navigationController.navigationBar.barTintColor = UIColor(rgba: "#295a9e")
		//navigationController.navigationBar.shadowImage = UIImage()
	
		UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_18pt")
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_18pt")
		
		let menuController = NavigationMenuViewController()
		menuController.server = server
		
		let vc = menuController.createViewController(NSIndexPath(forItem: 0, inSection: 0))
		
		drawerController = DrawerController(centerViewController: vc!, leftDrawerViewController: menuController)
		drawerController.maximumRightDrawerWidth = 200.0
		drawerController.openDrawerGestureModeMask = .All
		drawerController.closeDrawerGestureModeMask = .All
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
			NSLog("Sign in: \(user.userID)")
            server.accounts.insert(AppEngineAccount(email: user.profile.email, token: user.authentication.accessToken), atIndex: 0)
            if let menuController = drawerController.leftDrawerViewController as? NavigationMenuViewController
            {
                menuController.tableView.reloadData()
            }
		}
		else
		{
			NSLog("Sign in error: \(error.localizedDescription)")
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
				// TODO load into experience view controller
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

