//
//  Constants.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

struct Constants {
    
    struct Color {
        
        static let errorBanner = UIColor(red: 242/255, green: 81/255, blue: 99/255, alpha: 1)
        static let loginSignupPlaceholder = UIColor(red: 245/255, green: 173/255, blue: 175/255, alpha: 1)
        static let offWhite = UIColor(red: 251/255, green: 248/255, blue: 244/255, alpha: 1)
        static let darkTeal = UIColor(red: 63/255, green: 184/255, blue: 175/255, alpha: 1)
        static let lightTeal = UIColor(red: 199/255, green: 233/255, blue: 232/255, alpha: 1)
    }

    struct CellReuseIdentifier {
        
        static let timelineCell = "TimelineCell"
        static let viewEntryCell = "ViewEntryCell"
        static let settingsIconCell = "SettingsIconCell"
    }
    
    struct ClassName {
        
        static let timelineTableViewCellXib = "TimelineTableViewCell"
        static let viewEntryTableViewCellXib = "ViewEntryTableViewCell"
        static let settingsIconTableViewCellXib = "SettingsIconTableViewCell"
    }
    
    struct ImageName {
        
        static let angry = "angry-60"
        static let bothered = "bothered-60"
        static let sad = "sad-60"
        static let happy = "happy-60"
        static let reallyHappy = "really-happy-60"
        static let superExcited = "super-excited-60"
        static let gratitudeNavBar = "gratitude-35"
        static let composeButton = "compose-22"
        static let settingsButton = "settings-22"
        static let settingsSignoutButton = "signout-30"
        static let backButton = "back-22"
        static let saveButton = "save-22"
        static let cancelButton = "cancel-22"
        static let camera = "camera-128"
        static let imagePlaceholder = "image-placeholder-512"
    }
    
    struct Firebase {
        
        static let connectedPath = ".info/connected"
        
        static let usersKey = "users"
        
        struct User {
            
            static let nameKey = "name"
            static let emailKey = "email"
        }
        
        static let entriesKey = "entries"
        
        struct Entry {
            
            static let textKey = "text"
            static let imageUrlKey = "imageUrl"
            static let aspectRatioKey = "aspectRatio"
            static let createdDateKey = "createdDate"
            static let happinessLevelKey = "happinessLevel"
            static let placemarkKey = "placemark"
            static let locationKey = "location"
        }
        
        struct Location {
            
            static let nameKey = "name"
            static let latitudeKey = "latitude"
            static let longitudeKey = "longitude"
        }
        
        static let entryImagesKey = "entryImages"
    }
    
    struct GoogleMaps {
        
        static let baseUrl = "https://maps.googleapis.com/maps/api/geocode/json?"
        static let apiKey = "AIzaSyDn1Qzrh31SwpZHDFKzrN5zWPWi6Qpcq5c"
    }
    
    struct UserDefaults {
        
        static let currentUserKey = "currentUser"

        struct User {
            
            static let idKey = "id"
            static let nameKey = "name"
            static let emailKey = "email"
        }
    }

    struct NotificationName {
        
        static let userDidLogin = Notification.Name(rawValue: "userDidLoginNotification")
        static let userDidSignout = Notification.Name(rawValue: "userDidSignoutNotification")
        static let newEntry = Notification.Name(rawValue: "newEntry")
        static let replaceEntry = Notification.Name(rawValue: "replaceEntry")
        static let deleteEntry = Notification.Name(rawValue: "deleteEntry")
    }

    static func dateString(from date: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d y" // Nov 12, 2016
        let dateString = formatter.string(from: date)
        return dateString
    }
    
    // Return the week and year of the specified date.
    static func getWeekYear(date: Date?) -> (Int, Int) {
        
        let week: Int
        let year: Int
        if let date = date {
            
            week = Calendar.current.component(.weekOfYear, from: date)
            year = Calendar.current.component(.yearForWeekOfYear, from: date)
        }
        else {
            
            week = 0
            year = 0
        }
        
        return (week, year)
    }

    static func setRoundCornersForAspectFit(imageView: UIImageView, radius: CGFloat) {
        
        if let image = imageView.image {
            
            let boundsScale = imageView.bounds.size.width / imageView.bounds.size.height
            let imageScale = image.size.width / image.size.height
            var drawingRect = imageView.bounds
            if boundsScale > imageScale {
                
                drawingRect.size.width =  drawingRect.size.height * imageScale
                drawingRect.origin.x = (imageView.bounds.size.width - drawingRect.size.width) / 2
            }
            else {
                
                drawingRect.size.height = drawingRect.size.width / imageScale
                drawingRect.origin.y = (imageView.bounds.size.height - drawingRect.size.height) / 2
            }
            let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: radius)
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            imageView.layer.mask = mask
        }
    }
}
