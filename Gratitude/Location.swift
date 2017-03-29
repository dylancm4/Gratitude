//
//  Location.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

// Represents a location.
class Location {
    
    var name: String?
    var latitude: Float?
    var longitude: Float?
    
    // Description of the Location for the GUI.
    var description: String {
        
        get {
            
            if let name = name, name.characters.count > 0 {
                
                return name
            }
            
            if let latitude = latitude, let longitude = longitude {
                
                if let address = GoogleMapsClient.shared.getAddressDescription(latitude: latitude, longitude: longitude) {
                    
                    return address
                }
                else {
                    
                    return "\(latitude), \(longitude)"
                }
            }
            else {
                
                return ""
            }
        }
    }
    
    // Dictionary representation of the Location to be stored in the database.
    var dictionary: [String: Any] {
        
        get {
            
            let name = self.name ?? ""
            let latitude = self.latitude ?? 0.0
            let longitude = self.longitude ?? 0.0
            let dictionary = [
                Constants.Firebase.Location.nameKey: name,
                Constants.Firebase.Location.latitudeKey: latitude,
                Constants.Firebase.Location.longitudeKey: longitude] as [String : Any]
            return dictionary
        }
    }

    init() {
        
    }
    
    // Creates a Location from the database dictionary.
    init(dictionary: AnyObject) {
        
        name = dictionary.object(forKey: Constants.Firebase.Location.nameKey) as? String
        latitude = dictionary.object(forKey: Constants.Firebase.Location.latitudeKey) as? Float
        longitude = dictionary.object(forKey: Constants.Firebase.Location.longitudeKey) as? Float
    }
    
    init(name: String?, latitude: Float?, longitude: Float?) {
        
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
