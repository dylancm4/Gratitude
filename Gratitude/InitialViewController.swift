//
//  InitialViewController.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    override func viewDidLoad() {
        
        super.viewDidLoad()

        signupButton.layer.cornerRadius = 3
        signupButton.layer.masksToBounds = true
        
        loginButton.layer.cornerRadius = 3
        loginButton.layer.masksToBounds = true
    }
    
    @IBAction func onSignupButton(_ sender: UIButton) {
        
        let signupViewController = LoginSignupViewController(nibName: "LoginSignupViewController", bundle: nil)
        signupViewController.isSignup = true
        navigationController?.pushViewController(signupViewController, animated: true)
    }
    
    @IBAction func onLoginButton(_ sender: UIButton) {
        
        let loginViewController = LoginSignupViewController(nibName: "LoginSignupViewController", bundle: nil)
        loginViewController.isSignup = false
        navigationController?.pushViewController(loginViewController, animated: true)
    }
}
