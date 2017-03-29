//
//  ViewControllerBase.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class ViewControllerBase: UIViewController {

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
}
