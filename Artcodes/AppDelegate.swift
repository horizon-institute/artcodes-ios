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
import GoogleSignIn
import SideMenu

@main
class ArtcodeAppDelegate: UIResponder, UIApplicationDelegate, UINavigationControllerDelegate
{
    let server = CardographerServer()
    
    var window: UIWindow?
    var navigation = UINavigationController()
    let menu = SideMenuController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
    {       
        let cache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
        URLCache.shared = cache
        
        if(Feature.isEnabled(feature: "feature_show_local"))
        {
            server.accounts["local"] = LocalAccount()
        }
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn()
        {
            GIDSignIn.sharedInstance.restorePreviousSignIn() { user, error in
                if let user = user {
                    if let profile = user.profile {
                        self.server.addAccount(name: profile.name, email: profile.email, token: user.accessToken.tokenString)
                    }
                }
            }
        }
                   
        SideMenuController.preferences.basic.menuWidth = 240
        let sideMenu = MenuViewController()
        menu.menuViewController = sideMenu
        menu.contentViewController = RecommendedViewController()
        menu.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_menu"), style: .plain, target: self, action: #selector(toggleDrawer))
        menu.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_search"), style: .plain, target: self, action: #selector(search))

        
        navigation.delegate = self
        navigation.pushViewController(menu, animated: false)
                
        if(!Feature.isEnabled(feature: "feature_hide_welcome"))
        {
            print("Show Intro")
            navigation.pushViewController(AboutArtcodesViewController(), animated: false)
        }
                
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        window?.rootViewController = navigation
        window?.makeKeyAndVisible()
        print("Setup Complete")
        return true
    }
    
    @objc func toggleDrawer() {
        if(menu.isMenuRevealed) {
            menu.hideMenu()
        } else {
            menu.revealMenu()
        }
    }
    
    @objc func search()
    {
        navigation.pushViewController(SearchViewController(), animated: true)
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        print("Handle url: \(url)")
        openExperience(id: url.absoluteString)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
    {
        print("Url: \(url)")
        let handled = GIDSignIn.sharedInstance.handle(url)
        if !handled
        {
            print("URL: %@", url)
            if url.scheme == "x-scan-artcode"
            {
                // TODO open scanning view controller
            }
            else
            {
                openExperience(id: url.absoluteString)
            }
        }
        
        return handled
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool
    {
        print("userActivity.activityType: \(userActivity.activityType)")
        if userActivity.activityType == "NSUserActivityTypeBrowsingWeb"
        {
            print("userActivity.webpageURL: \(userActivity.webpageURL)")
            if let url = userActivity.webpageURL
            {
                if url.absoluteString.starts(with: server.root)
                {
                    openExperience(id: url.absoluteString)
                }
            }
        }
        return true
    }
    
    func openExperience(id: String)
    {
        var recent = server.recent
        if recent.contains(id)
        {
            if let index = recent.firstIndex(of: id) {
                recent.remove(at: index)
            }
        }
            
        recent.insert(id, at: 0)
        server.recent = recent
        server.loadExperience(uri: id) { (result) -> Void in
            if let experience = try? result.get() {
                self.navigation.pushViewController(ExperienceViewController(experience), animated: false)
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is AboutArtcodesViewController {
            navigation.setNavigationBarHidden(true, animated: animated)
        } else if viewController is ExperienceViewController || viewController is ArtcodeViewController {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                appearance.backgroundImage = UIImage(named: "shim")
                appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                navigation.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.setBackIndicatorImage(UIImage(named: "ic_arrow_back"), transitionMaskImage: nil)
                navigation.navigationBar.standardAppearance = appearance
                navigation.navigationBar.scrollEdgeAppearance = appearance
            } else {
                navigation.navigationBar.isTranslucent = false
                navigation.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
                navigation.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navigation.navigationBar.barTintColor = UIColor(hex6: 0x324A5E)
                navigation.navigationBar.shadowImage = UIImage()
                UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_white")
                UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_white")
            }
            navigation.navigationBar.tintColor = UIColor.white
            navigation.setNavigationBarHidden(false, animated: animated)
        } else {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(hex6: 0x324A5E)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.setBackIndicatorImage(UIImage(named: "ic_arrow_back"), transitionMaskImage: nil)
                navigation.navigationBar.standardAppearance = appearance
                navigation.navigationBar.scrollEdgeAppearance = appearance
            } else {
                navigation.navigationBar.isTranslucent = false
                navigation.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
                navigation.navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navigation.navigationBar.barTintColor = UIColor(hex6: 0x324A5E)
                navigation.navigationBar.shadowImage = UIImage()
                UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_arrow_back_white")
                UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_arrow_back_white")
            }
            navigation.navigationBar.tintColor = UIColor.white
            navigation.setNavigationBarHidden(false, animated: animated)
        }
    }
}
