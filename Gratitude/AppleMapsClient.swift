//
//  AppleMapsClient.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/26/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import CoreLocation

// Class which interfaces with CoreLocation.
class AppleMapsClient {
    
    // Shared instance.
    static var shared = AppleMapsClient()
    
    func getAreaOfInterest(location: CLLocation, completion: @escaping (_ areaOfInterest: String?, _ error: Error?) -> ()) {
        
        CLGeocoder().reverseGeocodeLocation(
            location,
            completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) -> Void in
                
                if error != nil {
                    
                    completion(nil, error)
                }
                
                var placeOfInterest: String? = nil
                if let placemarks = placemarks, placemarks.count > 0 {
                    
                    let placemark = placemarks[0]
                    if let areasOfInterest = placemark.areasOfInterest, areasOfInterest.count > 0 {

                        placeOfInterest = areasOfInterest[0]
                    }
                    else if let locality = placemark.locality, let administrativeArea = placemark.administrativeArea {
                        
                        placeOfInterest = "\(locality), \(administrativeArea)"
                    }
                }
                completion(placeOfInterest, nil)
            })
    }
}
