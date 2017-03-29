//
//  GoogleMapsClient.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation

// Client which interfaces with the Google Maps API.
class GoogleMapsClient {
    
    // Shared instance.
    static var shared = GoogleMapsClient()

    // Return a description of the address corresponding to the specified
    // latitude and longitude.
    func getAddressDescription(latitude: Float, longitude: Float) -> String? {
        
        var address: String? = nil
        if let url = NSURL(string: "\(Constants.GoogleMaps.baseUrl)latlng=\(latitude),\(longitude)&key=\(Constants.GoogleMaps.apiKey)") {
            
            if let data = NSData(contentsOf: url as URL) {
                
                var json: NSDictionary?
                do {
                    
                    json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
                }
                catch {
                    
                    json = nil
                }
                
                if let json = json {
                    
                    if let result = json["results"] as? NSArray, result.count > 0 {
                        
                        if let addressArray = result[0] as? NSDictionary {
                            
                            address = addressArray["formatted_address"] as? String
                            if let addressComponents = addressArray["address_components"] as? NSArray {
                                
                                var city = ""
                                if addressComponents.count > 2 {
                                    
                                    if let cityArray = addressComponents[2] as? NSDictionary {
                                        
                                        city = cityArray["long_name"] as! String
                                    }
                                }
                                
                                var state = ""
                                if addressComponents.count > 4 {
                                    
                                    if let stateArray = addressComponents[4] as? NSDictionary {
                                        
                                        state = stateArray["short_name"] as! String
                                    }
                                }
                                
                                if city.characters.count > 0 && state.characters.count > 0 {
                                    
                                    address = "\(city), \(state)"
                                    
                                }
                                else if city.characters.count > 0 {
                                    
                                    address = "\(city)"
                                }
                            }
                        }
                    }
                }
            }
        }
        return address
    }
}
