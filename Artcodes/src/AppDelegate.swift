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
				print("Using \(alteredURL)")
				return testURL
			}
		}
		
		print("Using \(url)")
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
				print("Error creatingDirectory \(dir): \(error)")
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
		assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
		
		// Optional: configure GAI options.
		let gai = GAI.sharedInstance()
		gai?.trackUncaughtExceptions = true
		if _isDebugAssertConfiguration()
		{
			print("Running in debug build")
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
			print("Signin silently")
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
	
	func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!)
	{
		if (error == nil)
		{
			print("Signed in as \(user.profile.name) (\(user.userID)) using \(signIn)")
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
			print("Sign in error: \(error.localizedDescription)")
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
		print("User account disconnected \(error)")
	}
	
	func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool
	{
		if url.absoluteString.contains("://aestheticodes.appspot.com/experience/info/")
		{
			openExperience(url.absoluteString.replacingOccurrences(of: "://aestheticodes.appspot.com/experience/info/", with: "://aestheticodes.appspot.com/experience/"))
		}
		else
		{
			openExperience(url.absoluteString)
		}
		return true
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
		print("userActivity.activityType: \(userActivity.activityType)")
		if userActivity.activityType == "NSUserActivityTypeBrowsingWeb"
		{
			print("userActivity.webpageURL: \(userActivity.webpageURL.debugDescription)")
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
	
	func applicationWillResignActive(_ application: UIApplication) {}
	
	func applicationDidEnterBackground(_ application: UIApplication) {}
	
	func applicationWillEnterForeground(_ application: UIApplication) {}
	
	func applicationDidBecomeActive(_ application: UIApplication) {}
	
	func applicationWillTerminate(_ application: UIApplication) {}
}

