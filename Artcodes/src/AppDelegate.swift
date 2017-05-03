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
import GooglePlaces

@UIApplicationMain
class ArtcodeAppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate
{
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
		//TODO
		return
	}

	static let googleChromeHTTPScheme: String = "googlechrome:"
	static let googleChromeHTTPSScheme: String = "googlechromes:"
	
	static func chromifyURL(_ url: String) -> URL?
	{
		var alteredURL = url
		if alteredURL.hasPrefix("http://")
		{
			alteredURL = alteredURL.replacingOccurrences(of: "http://", with: googleChromeHTTPScheme)
		}
		else if alteredURL.hasPrefix("https://")
		{
			alteredURL = alteredURL.replacingOccurrences(of: "https://", with: googleChromeHTTPSScheme)
		}
		
		if let testURL = URL(string: alteredURL)
		{
			if(UIApplication.shared.canOpenURL(testURL))
			{
				NSLog("Using %@", alteredURL)
				return testURL
			}
		}
		
		NSLog("Using %@", url)
		return URL(string: url)
	}
	
	static func getDirectory(_ name: String) -> URL?
	{
		let fileManager = FileManager.default
		let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
		if let documentDirectory:URL = urls.first
		{
			let dir = documentDirectory.appendingPathComponent(name, isDirectory: true)
			
				do
				{
					try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
				}
				catch
				{
					NSLog("Error: %@", "\(error)")
				}
				return dir
			
		}
		else
		{
			print("Couldn't get documents directory!")
		}
		
		return nil
	}
	
	
	static let imageCache = NSCache<AnyObject, AnyObject>()
	var navigationController: UINavigationController!
	let server = AppEngineServer()
	var drawerController: DrawerController!
	var window: UIWindow?
	var silent = false
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
	{
		// Configure tracker from GoogleService-Info.plist.
		var configureError:NSError?
		GGLContext.sharedInstance().configureWithError(&configureError)
		assert(configureError == nil, "Error configuring Google services: \(configureError)")
		
		// Optional: configure GAI options.
		let gai = GAI.sharedInstance()
		gai?.trackUncaughtExceptions = true
		if _isDebugAssertConfiguration()
		{
			NSLog("Debugging")
			gai?.logger.logLevel = GAILogLevel.verbose
			gai?.dryRun = true
		}
		
		let URLCache = Foundation.URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
		Foundation.URLCache.shared = URLCache
		
		if(Feature.isEnabled("feature_show_local"))
		{
			server.accounts["local"] = LocalAccount()
		}
		
		GIDSignIn.sharedInstance().delegate = self
		if GIDSignIn.sharedInstance().hasAuthInKeychain()
		{
			silent = true
			GIDSignIn.sharedInstance().signInSilently()
		}
		
		if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
		{
			if let dict = NSDictionary(contentsOfFile: path)
			{
				if let apiKey = dict["API_KEY"] as? String
				{
					GMSServices.provideAPIKey(apiKey)
					GMSPlacesClient.provideAPIKey(apiKey)
				}
			}
		}
		
		UIApplication.shared.statusBarStyle = .lightContent
		
		navigationController = UINavigationController()
		navigationController.navigationBar.isTranslucent = false
		navigationController.navigationBar.tintColor = UIColor.white
		navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
		navigationController.navigationBar.barTintColor = UIColor(hex6: 0x324A5E)
		navigationController.navigationBar.shadowImage = UIImage()
		
		UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_white")
		UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_white")
		
		let menuController = NavigationMenuViewController()
		drawerController = DrawerController(centerViewController: RecommendedViewController(), leftDrawerViewController: menuController)
		drawerController.maximumRightDrawerWidth = 200.0
		drawerController.openDrawerGestureModeMask = .all
		drawerController.closeDrawerGestureModeMask = .all
		drawerController.title = NSLocalizedString("recommended", tableName: nil, bundle: Bundle.main, value: "Recommended", comment: "")
		drawerController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_menu"), style: .plain, target: self, action: #selector(ArtcodeAppDelegate.toggleMenu))
		drawerController.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_search"), style: .plain, target: self, action: #selector(ArtcodeAppDelegate.search))
		
		menuController.drawerController = drawerController
		
		navigationController.pushViewController(drawerController, animated: false)
		
		if(!Feature.isEnabled("feature_hide_welcome"))
		{
			navigationController.pushViewController(AboutArtcodesViewController(), animated: false)
		}
		
		window = UIWindow(frame: UIScreen.main.bounds)
		if let window = window
		{
			window.backgroundColor = UIColor.white
			window.rootViewController = navigationController
			window.makeKeyAndVisible()
		}
		
		
		return true
	}
	
	func toggleMenu()
	{
		drawerController.toggleDrawerSide(.left, animated: true, completion: nil)
	}
	
	func search()
	{
		navigationController.pushViewController(SearchViewController(), animated: true)
	}
	
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: NSError!)
	{
		if (error == nil)
		{
			NSLog("Signed in as %@ (%@) using %@", user.profile.name, user.userID, signIn)
			let account = AppEngineAccount(email: user.profile.email, name: user.profile.name, token: user.authentication.accessToken)
			server.accounts[account.id] = account
			if drawerController != nil
			{
				if let menuController = drawerController.leftDrawerViewController as? NavigationMenuViewController
				{
					menuController.tableView.reloadData()
					if !silent
					{
						drawerController.title = account.name
						//drawerController.setCenterViewController(AccountViewController(account: account), withCloseAnimation: true, completion: nil)
						drawerController.centerViewController = AccountViewController(account: account)
					}
					else if let accountController = drawerController.centerViewController as? AccountViewController
					{
						if accountController.account.id == account.id
						{
							drawerController.centerViewController = AccountViewController(account: account)
						}
					}
				}
			}
		}
		else
		{
			NSLog("Sign in error: %@", error.localizedDescription)
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
		silent = false
	}
	
	func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!, withError error: Error!)
	{
		NSLog("Disconnected")
	}
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
	{
		let handled = GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
		if !handled
		{
			//NSLog("URL: %@", url)
			if url.scheme == "x-scan-artcode"
			{
				// TODO open scanning view controller
			}
			else
			{
				if url.absoluteString.contains("://aestheticodes.appspot.com/experience/info/")
				{
					openExperience(url.absoluteString.replacingOccurrences(of: "://aestheticodes.appspot.com/experience/info/", with: "://aestheticodes.appspot.com/experience/"))
				}
				else
				{
					openExperience(url.absoluteString)
				}
			}
		}
		
		return handled
	}
	
	func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool
	{
		NSLog("userActivity.activityType: %@", userActivity.activityType)
		if userActivity.activityType == "NSUserActivityTypeBrowsingWeb"
		{
			NSLog("userActivity.webpageURL: %@", "\(userActivity.webpageURL)")
			if let url = userActivity.webpageURL
			{
				if url.absoluteString.contains("://aestheticodes.appspot.com/experience/info/")
				{
					openExperience(url.absoluteString.replacingOccurrences(of: "://aestheticodes.appspot.com/experience/info/", with: "://aestheticodes.appspot.com/experience/"))
				}
				else
				{
					openExperience(url.absoluteString)
				}
			}
		}
		return true
	}
	
	func openExperience(_ id: String)
	{
		var recent = server.recent
		if recent.contains(id)
		{
			recent.removeObject(id)
		}
			
		recent.insert(id, at: 0)
		server.recent = recent
		server.loadExperience(id, success: { (experience) -> Void in
								self.navigationController.pushViewController(ExperienceViewController(experience: experience), animated: false)
			}, failure: { (error) -> Void in
		})
	}
	
	func applicationWillResignActive(_ application: UIApplication)
	{
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication)
	{
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication)
	{
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication)
	{
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
}

