//
//  EntryBroker.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

// Manages Entry creation, updating, and deletion.
class EntryBroker {
    
    static var shared = EntryBroker()
    
    var currentViewController: UIViewController?

    // Create a new entry based on the specified parameters.
    func createEntry(text: String, image: UIImage?, happinessLevel: Int, placemark: String?, location: Location?) {
        
        // Create a temporary "local" entry so that the user will immediately
        // see the entry they created. This "local" entry will receive special
        // treatment (e.g., no editing, no deleting).
        let localEntry = Entry(text: text, image: image, happinessLevel: happinessLevel, placemark: placemark, createdDate: Date())
        NotificationCenter.default.post(name: Constants.NotificationName.newEntry, object: localEntry)
        
        FirebaseClient.shared.createEntry(
            text: text,
            image: image,
            happinessLevel: happinessLevel,
            placemark: placemark,
            location: location,
            success: { (newEntry: Entry) in
                
                // Success, replace the temporary "local" entry with the new entry.
                let notificationObject = ReplaceEntryNotificationObject(entryId: localEntry.id!, replacementEntry: newEntry, useFadeAnimation: false)
                NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)
            },
            failure: { (error: Error) in
                
                // Failure, delete the temporary "local" entry.
                NotificationCenter.default.post(name: Constants.NotificationName.deleteEntry, object: localEntry)

                let alertController = UIAlertController(title: "Error saving entry", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                }))
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                    self.createEntry(text: text, image: image, happinessLevel: happinessLevel, placemark: placemark, location: location)
                }))
                self.currentViewController?.present(alertController, animated: true, completion: nil)
            })
    }
    
    // Update the specified entry based on the specified parameters.
    func updateEntry(originalEntry: Entry, text: String, image: UIImage?, happinessLevel: Int, placemark: String?, location: Location?) {
        
        // Replace the original entry with a temporary "local" entry, so that
        // the user will immediately see the changes.
        let localEntry = Entry(text: text, image: image, happinessLevel: happinessLevel, placemark: placemark, createdDate: originalEntry.createdDate)
        let notificationObject = ReplaceEntryNotificationObject(entryId: originalEntry.id!, replacementEntry: localEntry, useFadeAnimation: false)
        NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)
        
        FirebaseClient.shared.updateEntry(
            entryId: originalEntry.id!,
            text: text,
            image: image,
            happinessLevel: happinessLevel,
            placemark: placemark,
            location: location,
            success: { (updatedEntry: Entry) in
                
                // Success, replace the temporary "local" entry with the updated entry.
                let notificationObject = ReplaceEntryNotificationObject(entryId: localEntry.id!, replacementEntry: updatedEntry, useFadeAnimation: false)
                NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)
            },
            failure: { (error: Error) in
                
                // Failure, replace the temporary "local" entry with the original entry.
                let notificationObject = ReplaceEntryNotificationObject(entryId: localEntry.id!, replacementEntry: originalEntry, useFadeAnimation: false)
                NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)

                let alertController = UIAlertController(title: "Error saving entry", message:
                    error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                }))
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                    self.updateEntry(originalEntry: originalEntry, text: text, image: image, happinessLevel: happinessLevel, placemark: placemark, location: location)
                }))
                self.currentViewController?.present(alertController, animated: true, completion: nil)
            })
    }
    
    // Delete the specified entry.
    func deleteEntry(entry: Entry) {
        
        // Mark this entry for deletion to indicate this entry is currently in
        // the process of being deleted, replacing the current entry with the
        // marked entry, so that the user will immediately see the entry
        // disappear.
        entry.markForDelete(true)
        let notificationObject = ReplaceEntryNotificationObject(entryId: entry.id!, replacementEntry: entry, useFadeAnimation: true)
        NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)

        FirebaseClient.shared.deleteEntry(
            entry: entry,
            success: { () in
                
                // Success, delete the entry.
                NotificationCenter.default.post(name: Constants.NotificationName.deleteEntry, object: entry)
            },
            failure: { (error: Error) in
                
                // Failure, unmark this entry for deletion so that it
                // appears again.
                entry.markForDelete(false)
                let notificationObject = ReplaceEntryNotificationObject(entryId: entry.id!, replacementEntry: entry, useFadeAnimation: true)

                let alertController = UIAlertController(title: "Error deleting entry", message:
                    error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                    NotificationCenter.default.post(name: Constants.NotificationName.replaceEntry, object: notificationObject)
                }))
                alertController.addAction(UIAlertAction(title: "Try again", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction) in
                    
                    self.deleteEntry(entry: entry)
                }))
                self.currentViewController?.present(alertController, animated: true, completion: nil)
            })
    }
}
