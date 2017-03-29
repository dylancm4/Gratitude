//
//  SettingsViewController.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Navigation bar
        navigationItem.title = "Settings"
        navigationController?.navigationBar.isTranslucent = false
        
        // Set the navigation bar back button.
        let backButton = UIBarButtonItem(
            image: UIImage(named: Constants.ImageName.backButton), style: .plain, target: self, action: #selector(SettingsViewController.onBackButton))
        navigationItem.leftBarButtonItem = backButton
        
        // Set up the tableView.
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(
            UINib(nibName: Constants.ClassName.settingsIconTableViewCellXib, bundle: nil),
            forCellReuseIdentifier: Constants.CellReuseIdentifier.settingsIconCell)
    }

    func onBackButton() {
        
        _ = navigationController?.popViewController(animated: true)
    }

    func onSignout() {
        
        let alert = UIAlertController(title: "Sign out?", message: "Are you sure you want to sign out?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(
            title: "Sign out",
            style: UIAlertActionStyle.default,
            handler: { (action: UIAlertAction) in
                
                NotificationCenter.default.post(name: Constants.NotificationName.userDidSignout, object: nil)
            }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

// UITableView methods
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellReuseIdentifier.settingsIconCell) as! SettingsIconTableViewCell
            
        // Set the cell contents.
        cell.setData(imageName: Constants.ImageName.settingsSignoutButton, title: "Sign out")
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Do not leave rows selected.
        tableView.deselectRow(at: indexPath, animated: true)

        onSignout()
    }
}
