//
//  ReplaceEntryNotificationObject.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/26/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation

// Object for replaceEntryNotification. The entryId identifies which entry to
// replace, and the replacementEntry identifies the replacement entry.
class ReplaceEntryNotificationObject {
    
    var entryId: String
    var replacementEntry: Entry
    var useFadeAnimation: Bool
    
    init(entryId: String, replacementEntry: Entry, useFadeAnimation: Bool) {
        
        self.entryId = entryId
        self.replacementEntry = replacementEntry
        self.useFadeAnimation = useFadeAnimation
    }
}
