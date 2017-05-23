//
//  Entry.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/15/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

enum HappinessLevel: Int {
    
    case angry
    case bothered
    case sad
    case happy
    case excited
    case superExcited
}

// Represents a journal entry.
class Entry {
    
    var id: String?
    var text: String?
    var imageUrl: URL?
    var aspectRatio: Double?
    var videoUrl: URL?
    var createdDate: Date?
    var happinessLevel: HappinessLevel?
    var placemark: String?
    
    // Indicates whether this is a temporary "local" entry which has not yet
    // been saved to the database.
    var isLocal = false
    
    // Image for a temporary "local" entry.
    var localImage: UIImage?
    
    // Video file URL for a temporary "local" entry.
    var localVideoFileUrl: URL?
    
    // Indicates whether a temporary "local" entry is a video entry.
    var isLocalVideoEntry = false
    
    // Indicates whether this entry is currently in the process of being deleted.
    var isLocalMarkedForDelete = false
    
    // Creates an Entry from the database dictionary.
    init(id: String, dictionary: AnyObject) {
        
        self.id = id
        self.text = dictionary.object(forKey: Constants.Firebase.Entry.textKey) as? String
        
        if let imageUrlString = dictionary.object(forKey: Constants.Firebase.Entry.imageUrlKey) as? String {
            
            self.imageUrl = URL(string: imageUrlString)
        }
        else {
            
            self.imageUrl = nil
        }
        
        self.aspectRatio = dictionary.object(forKey: Constants.Firebase.Entry.aspectRatioKey) as? Double
        
        if let videoUrlString = dictionary.object(forKey: Constants.Firebase.Entry.videoUrlKey) as? String {
            
            self.videoUrl = URL(string: videoUrlString)
        }
        else {
            
            self.videoUrl = nil
        }
        
        if let createdDateInterval = dictionary.object(forKey: Constants.Firebase.Entry.createdDateKey) as? Double {
            
            self.createdDate = Date(timeIntervalSince1970: createdDateInterval)
        }

        if let happinessLevelValue = dictionary.object(forKey: Constants.Firebase.Entry.happinessLevelKey) as? Int {
            
            self.happinessLevel = Entry.getHappinessLevel(happinessLevelInt: happinessLevelValue)
        }
        else {
            
            self.happinessLevel = nil
        }
        
        if let placemark = dictionary.object(forKey: Constants.Firebase.Entry.placemarkKey) as? String {
            
            self.placemark = placemark
        }
        else if let locationDict = dictionary.object(forKey: Constants.Firebase.Entry.locationKey) {
                
            let location = Location.init(dictionary: locationDict as AnyObject)
            self.placemark = location.description
        }
        else {
            
            self.placemark = ""
        }
        
        self.isLocal = false
        self.localImage = nil
        self.localVideoFileUrl = nil
        self.isLocalVideoEntry = false
        self.isLocalMarkedForDelete = false
    }
    
    // Creates a temporary "local" Entry.
    init(text: String, image: UIImage?, videoUrl: URL?, videoFileUrl: URL?, isVideoEntry: Bool, happinessLevel: Int?, placemark: String?, createdDate: Date?) {
        
        self.id = "\(Int64(arc4random()))"
        self.text = text
        self.imageUrl = nil
        self.videoUrl = videoUrl
        self.createdDate = createdDate
        if let happinessLevel = happinessLevel {
            
            self.happinessLevel = Entry.getHappinessLevel(happinessLevelInt: happinessLevel)
        }
        else {
            
            self.happinessLevel = nil
        }
        self.placemark = placemark
        self.isLocal = true
        if let images = image {
            
            self.localImage = image
            self.aspectRatio = Double(images.size.width / images.size.height)
        }
        else {
            
            self.localImage = nil
            self.aspectRatio = nil
        }
        self.localVideoFileUrl = videoFileUrl
        self.isLocalVideoEntry = isVideoEntry
        self.isLocalMarkedForDelete = false
    }

    // Mark or unmark this entry for deletion. If an entry is marked, that
    // indicates that the entry is currently in the process of being deleted.
    // Such entries are treated as temporary "local" entries so that certain
    // features are disabled until the deletion is completed.
    func markForDelete(_ mark: Bool) {
        
        isLocal = mark
        isLocalMarkedForDelete = mark
    }
    
    class func getHappinessLevel(happinessLevelInt: Int) -> HappinessLevel {
        
        var happyLevel = HappinessLevel.happy
        switch happinessLevelInt {
            
        case 0:
            happyLevel = HappinessLevel.angry
        case 1:
            happyLevel = HappinessLevel.bothered
        case 2:
            happyLevel = HappinessLevel.sad
        case 3:
            happyLevel = HappinessLevel.happy
        case 4:
            happyLevel = HappinessLevel.excited
        case 5:
            happyLevel = HappinessLevel.superExcited
        default:
            happyLevel = HappinessLevel.happy
        }
        return happyLevel
    }
    
    class func getHappinessLevelInt(happinessLevel: HappinessLevel) -> Int {
        
        switch happinessLevel {
            
        case .angry:
            return 0
        case .bothered:
            return 1
        case .sad:
            return 2
        case .happy:
            return 3
        case .excited:
            return 4
        case .superExcited:
            return 5
        }
    }
    
    class func getHappinessLevelImage(_ happinessLevel: HappinessLevel) -> UIImage {
        switch happinessLevel {
        case .angry:
            return UIImage(named: Constants.ImageName.angry)!
        case .bothered:
            return UIImage(named: Constants.ImageName.bothered)!
        case .sad:
            return UIImage(named: Constants.ImageName.sad)!
        case .happy:
            return UIImage(named: Constants.ImageName.happy)!
        case .excited:
            return UIImage(named: Constants.ImageName.reallyHappy)!
        case .superExcited:
            return UIImage(named: Constants.ImageName.superExcited)!
        }
    }
}

