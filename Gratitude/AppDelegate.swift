//
//  AppDelegate.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Configure a default Firebase app.
        FirebaseClient.shared.configure()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        // Set up log in and sign out notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDidLogin), name: Constants.NotificationName.userDidLogin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDidSignout), name: Constants.NotificationName.userDidSignout, object: nil)
        
        if User.currentUser == nil || !FirebaseClient.shared.isSignedIn {
            
            presentLoginSignupScreens()
        }
        else {
            
            presentLoggedInScreens()
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func userDidLogin() {
        
        presentLoggedInScreens()
    }
    
    func userDidSignout() {
        
        FirebaseClient.shared.signOut(
            success: {
                
                self.presentLoginSignupScreens()
            },
            failure: { (error: Error) in
            
                if let navigationController = self.window?.rootViewController as? UINavigationController, let currentViewController = navigationController.visibleViewController {
                    
                    ErrorBanner.presentError(message: "Sign out failure", inView: currentViewController.view)
                }
            })
    }
    
    func presentLoginSignupScreens() {
        
        let initialViewController = InitialViewController(nibName: nil, bundle: nil)
        let initialNavigationController = UINavigationController(rootViewController: initialViewController)
        initialNavigationController.isNavigationBarHidden = true
        window?.rootViewController = initialNavigationController
    }
    
    func presentLoggedInScreens() {
        
        let timelineViewController = TimelineViewController(nibName: nil, bundle: nil)
        let timelineNavigationController = UINavigationController(rootViewController: timelineViewController)
        window?.rootViewController = timelineNavigationController
    }
}

