//
//  LoginSignupViewController.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class LoginSignupViewController: UIViewController {
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var loginSignupButton: UIButton!
    
    var isSignup: Bool!
    
    var progressHud: ProgressHUD?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        nameView.layer.cornerRadius = 5
        nameView.layer.masksToBounds = true

        nameTextField.attributedPlaceholder = NSAttributedString.init(string: nameTextField.placeholder!, attributes: [NSForegroundColorAttributeName: Constants.Color.loginSignupPlaceholder])
        nameTextField.delegate = self
        
        emailView.layer.cornerRadius = 5
        emailView.layer.masksToBounds = true

        emailTextField.attributedPlaceholder = NSAttributedString.init(string: emailTextField.placeholder!, attributes: [NSForegroundColorAttributeName: Constants.Color.loginSignupPlaceholder])
        emailTextField.delegate = self

        passwordView.layer.cornerRadius = 5
        passwordView.layer.masksToBounds = true
        
        passwordTextField.attributedPlaceholder = NSAttributedString.init(string: passwordTextField.placeholder!, attributes: [NSForegroundColorAttributeName: Constants.Color.loginSignupPlaceholder])
        passwordTextField.delegate = self

        backButton.layer.cornerRadius = 5
        backButton.layer.masksToBounds = true

        loginSignupButton.layer.cornerRadius = 5
        loginSignupButton.layer.masksToBounds = true

        if (isLoginFlow()) {
            
            nameView.isHidden = true
            loginSignupButton.setTitle("Log in", for: .normal)
        }
        else {
            
            loginSignupButton.setTitle("Sign up", for: .normal)
        }
        
        let tapBackground = UITapGestureRecognizer()
        tapBackground.numberOfTapsRequired = 1
        tapBackground.addTarget(self, action: #selector(LoginSignupViewController.dismissKeyboard))
        view.addGestureRecognizer(tapBackground)
        
        // Set up the ProgressHUD.
        progressHud = ProgressHUD(view: view)
        if let progressHud = progressHud {
            
            view.addSubview(progressHud)
        }
    }
    
    @IBAction func onBackButton(_ sender: UIButton) {

        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onLoginSignupButton(_ sender: UIButton) {
        
        if (isSignupFlow()) {
            
            if nameTextField.text?.characters.count == 0 {
                
                ErrorBanner.presentError(message: "Please enter your name", inView: view)
                return
            }
        }
        
        if (!isValidEmail(testStr: emailTextField.text!)) {
            
            ErrorBanner.presentError(message: "Please enter a valid e-mail address", inView: view)
            return
        }
        
        if passwordTextField.text?.characters.count == 0 {
            
            ErrorBanner.presentError(message: "Please enter a password", inView: view)
            return
        }
        
        if (isSignupFlow()) {
         
            // Display progress HUD before the request is made.
            if let progressHud = progressHud {
                
                progressHud.show(animated: true)
            }
            
            FirebaseClient.shared.signUp(
                email: emailTextField.text!,
                password: passwordTextField.text!,
                name: nameTextField.text!,
                success: { (user: User) in
                    
                    // Hide progress HUD after request is complete.
                    if let progressHud = self.progressHud {
                        
                        progressHud.hide(animated: true)
                    }
                    
                    NotificationCenter.default.post(name: Constants.NotificationName.userDidLogin, object: nil)
                },
                failure: { (error: Error) in
                    
                    // Hide progress HUD after request is complete.
                    if let progressHud = self.progressHud {
                        
                        progressHud.hide(animated: true)
                    }
                    
                    ErrorBanner.presentError(message: "Sign up failure", inView: self.view)
                    let alert = UIAlertController(title: "Sign up failure", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alert, animated: true)
                })
        }
        else {
            
            // Display progress HUD before the request is made.
            if let progressHud = progressHud {
                
                progressHud.show(animated: true)
            }
            
            FirebaseClient.shared.signIn(
                email: emailTextField.text!,
                password: passwordTextField.text!,
                success: { (user: User) in
                
                    // Hide progress HUD after request is complete.
                    if let progressHud = self.progressHud {
                        
                        progressHud.hide(animated: true)
                    }

                    NotificationCenter.default.post(name: Constants.NotificationName.userDidLogin, object: nil)
                },
                failure: { (error: Error) in
                
                    // Hide progress HUD after request is complete.
                    if let progressHud = self.progressHud {
                    
                        progressHud.hide(animated: true)
                    }
                    
                    ErrorBanner.presentError(message: "Sign in failure", inView: self.view)
                    let alert = UIAlertController(title: "Sign in failure", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alert, animated: true)
                })
        }
    }

    func dismissKeyboard() {
        
        for textField in [nameTextField, emailTextField, passwordTextField] {
            
            if (textField?.isFirstResponder)! {
                
                textField?.resignFirstResponder()
            }
        }
    }
    
    func isValidEmail(testStr: String) -> Bool {

        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func isSignupFlow() -> Bool {
        
        return isSignup
    }
    
    func isLoginFlow() -> Bool {
        
        return !isSignup
    }
}

extension LoginSignupViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
}

