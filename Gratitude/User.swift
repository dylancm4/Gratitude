//
//  User.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

// Represents a user account.
final class User: NSObject, NSCoding {
        
    var id: String?
    var name: String?
    var email: String?
    
    // Creates a User from the database dictionary.
    init(id: String, dictionary: AnyObject) {
        
        self.id = id
        name = dictionary.object(forKey: Constants.Firebase.User.nameKey) as? String
        email = dictionary.object(forKey: Constants.Firebase.User.emailKey) as? String
    }
    
    init(coder aDecoder: NSCoder) {
        
        id = aDecoder.decodeObject(forKey: Constants.UserDefaults.User.idKey) as? String
        name = aDecoder.decodeObject(forKey: Constants.UserDefaults.User.nameKey) as? String
        email = aDecoder.decodeObject(forKey: Constants.UserDefaults.User.emailKey) as? String
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(id, forKey: Constants.UserDefaults.User.idKey)
        aCoder.encode(name, forKey: Constants.UserDefaults.User.nameKey)
        aCoder.encode(email, forKey: Constants.UserDefaults.User.emailKey)
    }
    
    static var _currentUser: User?
    class var currentUser: User? {
        
        get {
            
            if _currentUser == nil {
                
                let defaults = UserDefaults.standard
                
                if let userData = defaults.object(forKey: Constants.UserDefaults.currentUserKey) as? Data {
                    
                    _currentUser = NSKeyedUnarchiver.unarchiveObject(with: userData) as? User
                }
            }
            return _currentUser
        }
        
        set(user) {
            
            _currentUser = user
            
            // Do not block the main thread.
            DispatchQueue.global(qos: .background).async {
                
                let defaults = UserDefaults.standard
                
                if let user = user {
                    
                    let savedData = NSKeyedArchiver.archivedData(withRootObject: user)
                    defaults.set(savedData, forKey: Constants.UserDefaults.currentUserKey)
                }
                else {
                    
                    defaults.removeObject(forKey: Constants.UserDefaults.currentUserKey)
                }
                
                defaults.synchronize()
            }
        }
    }
}
