//
//  ViewControllerBase.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewControllerBase: UIViewController {

    var progressHud: ProgressHUD?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set up the ProgressHUD.
        progressHud = ProgressHUD(view: view)
        if let progressHud = progressHud {
            
            view.addSubview(progressHud)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        
        // EntryBroker keeps a reference to the current view controller.
        EntryBroker.shared.currentViewController = self
    }

    override func viewWillDisappear(_ animated: Bool) {

        // Remove EntryBroker reference to the current view controller.
        if EntryBroker.shared.currentViewController == self {

            EntryBroker.shared.currentViewController = nil
        }
    }
    
    // Display progress HUD before the request is made.
    func willRequest() {
        
        if let progressHud = progressHud {
            
            progressHud.show(animated: true)
        }
    }
    
    // Show or hide the error banner based on success or failure. Hide the
    // progress HUD.
    func requestDidSucceed(_ success: Bool) {
        
        DispatchQueue.main.async {
            
            if !success {
                
                if let navigationController = self.navigationController {
                    
                    ErrorBanner.presentError(message: "Network Error", inView: navigationController.view)
                }
            }
            
            if let progressHud = self.progressHud {
                
                progressHud.hide(animated: true)
            }
        }
    }
    
    // Present the AVPlayerViewController for the specified video.
    func presentVideoPlayerViewController(forVideoUrl videoUrl: URL) {
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = AVPlayer(url: videoUrl)
        present(playerViewController, animated: true) {
            
            playerViewController.player!.play()
        }
    }
}
