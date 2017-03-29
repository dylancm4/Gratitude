//
//  FirebaseClient.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/8/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import Firebase

// Client which interfaces with the Firebase realtime database.
class FirebaseClient {
    
    // Shared instance.
    static var shared = FirebaseClient()
    
    var observeEntriesHandle: UInt?
    
    // True if a user is signed in, false otherwise.
    var isSignedIn: Bool {
        
        get {
            
            return FIRAuth.auth()?.currentUser != nil
        }
    }
    
    // Configure a default Firebase app. Should be called after the app is
    // launched.
    func configure() {
        
        FIRApp.configure()
    }
    
    // Create and sign in a user with the given email address and password.
    func signUp(email: String, password: String, name: String, success: @escaping (_ user: User) -> (), failure: @escaping (Error) -> ()) {

        FIRAuth.auth()?.createUser(
            withEmail: email,
            password: password,
            completion: { (user: FIRUser?, error: Error?) in // main thread
                
                if let error = error {
                    
                    failure(error)
                }
                else if let user = user {

                    let rootNode = FIRDatabase.database().reference()
                    let userNode = rootNode.child(Constants.Firebase.usersKey).child(user.uid)
                    let values = [
                        Constants.Firebase.User.nameKey: name,
                        Constants.Firebase.User.emailKey: email]
                    userNode.updateChildValues(
                        values,
                        withCompletionBlock: { (error: Error?, database: FIRDatabaseReference) in
                            
                            if let error = error {
                                
                                failure(error)
                            }
                            else {
                                
                                userNode.observeSingleEvent(
                                    of: .value,
                                    with: { (snapshot: FIRDataSnapshot) in
                                        
                                        let userId = snapshot.key
                                        let curUser = User(id: userId, dictionary: snapshot.value as AnyObject)
                                        User.currentUser = curUser
                                        success(curUser)
                                    })
                            }
                        })
                }
                else {
                    
                    let userInfo = [NSLocalizedDescriptionKey : "Error creating user."]
                    failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
                }
            })
    }
    
    // Sign in using an email address and password.
    func signIn(email: String, password: String, success: @escaping (_ user: User) -> (), failure: @escaping (Error) -> ()) {
        
        FIRAuth.auth()?.signIn(
            withEmail: email,
            password: password,
            completion: { (user: FIRUser?, error: Error?) in // main thread
            
                if let error = error {
                    
                    failure(error)
                }
                else if let user = user {
                    
                    let rootNode = FIRDatabase.database().reference()
                    let userNode = rootNode.child(Constants.Firebase.usersKey).child(user.uid)
                    userNode.observeSingleEvent(
                        of: .value,
                        with: { (snapshot: FIRDataSnapshot) in
                        
                            let userId = snapshot.key
                            let curUser = User(id: userId, dictionary: snapshot.value as AnyObject)
                            User.currentUser = curUser
                            success(curUser)
                        })
                }
                else {
                    
                    let userInfo = [NSLocalizedDescriptionKey : "Error signing in. User undefined."]
                    failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
                }
            })
    }
    
    // Sign out the current user.
    func signOut(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        do {
        
            try FIRAuth.auth()?.signOut()
        }
        catch let error {
            
            failure(error)
            return
        }
        
        User.currentUser = nil
        success()
    }
    
    // Create an entry node for the specified entry.
    func createEntry(text: String, image: UIImage?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        let funcSuccess = success
        let funcFailure = failure
        if let currentUserId = User.currentUser?.id {
            
            let rootNode = FIRDatabase.database().reference()
            let entryNode = rootNode.child(Constants.Firebase.entriesKey).child(currentUserId).childByAutoId()
            updateEntry(
                entryNode: entryNode,
                text: text,
                image: image,
                happinessLevel: happinessLevel,
                placemark: placemark,
                location: location,
                success: { (entry: Entry) in
                    
                    funcSuccess(entry)
                },
                failure: { (error: Error) in
                    
                    funcFailure(error)
                })
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error creating entry. User undefined."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }

    // Update the entry node for the specified entry.
    func updateEntry(entryId: String, text: String, image: UIImage?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        let funcSuccess = success
        let funcFailure = failure
        if let currentUserId = User.currentUser?.id {
            
            let rootNode = FIRDatabase.database().reference()
            let entryNode = rootNode.child(Constants.Firebase.entriesKey).child(currentUserId).child(entryId)
            updateEntry(
                entryNode: entryNode,
                text: text,
                image: image,
                happinessLevel: happinessLevel,
                placemark: placemark,
                location: location,
                success: { (entry: Entry) in
                    
                    funcSuccess(entry)
                },
                failure: { (error: Error) in
                    
                    funcFailure(error)
                })
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error updating entry. User undefined."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }
    
    // Create/update the entry node for the specified entry.
    private func updateEntry(entryNode: FIRDatabaseReference, text: String, image: UIImage?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        let funcSuccess = success
        let funcFailure = failure
        
        // Set up the entry node.
        var values = [
            Constants.Firebase.Entry.textKey: text,
            Constants.Firebase.Entry.createdDateKey: Date().timeIntervalSince1970,
            Constants.Firebase.Entry.happinessLevelKey: happinessLevel] as [String : Any]
        if let placemark = placemark {
            
            values[Constants.Firebase.Entry.placemarkKey] = placemark
        }
        if let location = location {
            
            values[Constants.Firebase.Entry.locationKey] = location.dictionary
        }
        
        if let image = image {
            
            // Resize the image
            let resizedImage = resizeImage(image: image, targetSize: CGSize.init(width: 600, height: 600))
            let aspectRatio = Double(resizedImage.size.width) / Double(resizedImage.size.height)
            
            // Create the storage node for the entry image.
            storeEntryImage(
                entryId: entryNode.key,
                image: resizedImage,
                success: { (imageUrl: String) in
                    
                    values[Constants.Firebase.Entry.imageUrlKey] = imageUrl
                    values[Constants.Firebase.Entry.aspectRatioKey] = aspectRatio
                    
                    // Create the entry node.
                    self.updateEntry(
                        entryNode: entryNode,
                        values: values,
                        success: { (entry: Entry) in
                            
                            funcSuccess(entry)
                        },
                        failure: { (error: Error) in
                            
                            funcFailure(error)
                        })
                },
                failure: { (error: Error) in
                
                    funcFailure(error)
                })
        }
        else { // no image
            
            // Create the entry node.
            updateEntry(
                entryNode: entryNode,
                values: values,
                success: { (entry: Entry) in
                    
                    funcSuccess(entry)
                },
                failure: { (error: Error) in
                    
                    funcFailure(error)
                })
        }
    }
    
    // Create/update the entry node for the specified entry.
    private func updateEntry(entryNode: FIRDatabaseReference, values: [AnyHashable : Any], success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        // Create the "entries" node which contains the entry.
        entryNode.updateChildValues(
            values,
            withCompletionBlock: { (error: Error?, database: FIRDatabaseReference) in
                
                if let error = error {
                    
                    failure(error)
                }
                else {
                    
                    entryNode.observeSingleEvent(
                        of: .value,
                        with: { (snapshot: FIRDataSnapshot) in
                            
                            let entryId = snapshot.key
                            let entry = Entry(id: entryId, dictionary: snapshot.value as AnyObject)
                            success(entry)
                        })
                }
            })
    }

    // Delete the entry node for the specified entry.
    func deleteEntry(entry: Entry, success: @escaping () -> (), failure: @escaping (Error) -> ()) {

        let funcSuccess = success
        let funcFailure = failure
        if let currentUserId = User.currentUser?.id, let entryId = entry.id {
            
            // Delete the entry node.
            let rootNode = FIRDatabase.database().reference()
            let entryNode = rootNode.child(Constants.Firebase.entriesKey).child(currentUserId).child(entryId)
            entryNode.removeValue(
                completionBlock: { (error: Error?, database: FIRDatabaseReference) in
                    
                    if let error = error {
                        
                        funcFailure(error)
                    }
                    else {
                        
                        if entry.imageUrl != nil {
                        
                            // Delete the storage node for the entry image.
                            self.deleteEntryImage(
                                entryId: entryId,
                                success: {
                                
                                    funcSuccess()
                                },
                                failure: { (error: Error) in
                            
                                    funcFailure(error)
                                })
                        }
                    }
                })
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error deleting entry. User or entry undefined."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }
    
    // Get existing entries.
    func getEntries(success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        if let currentUserId = User.currentUser?.id {
            
            var existingEntriesLoaded = false
            
            // Does "entries" node exist?
            let rootNode = FIRDatabase.database().reference()
            rootNode.observeSingleEvent(
                of: .value,
                with: { (snapshot: FIRDataSnapshot) in
                    
                    if snapshot.hasChild(Constants.Firebase.entriesKey) {
                        
                        // Does user ID node exist under "entries" node?
                        let entriesNode = rootNode.child(Constants.Firebase.entriesKey)
                        entriesNode.observeSingleEvent(
                            of: .value,
                            with: { (snapshot: FIRDataSnapshot) in
                                
                                if snapshot.hasChild(currentUserId) {
                                    
                                    // User entries node exists, observe its children/entries.
                                    let userEntriesNode = entriesNode.child(currentUserId)
                                    self.observeEntriesHandle = userEntriesNode.observe(
                                        .childAdded,
                                        with: { (snapshot: FIRDataSnapshot) in
                                            
                                            if !existingEntriesLoaded {
                                                
                                                let entryId = snapshot.key
                                                let entry = Entry(id: entryId, dictionary: snapshot.value as AnyObject)
                                                NotificationCenter.default.post(name: Constants.NotificationName.newEntry, object: entry)
                                            }
                                            else if let observeEntriesHandle = self.observeEntriesHandle {
                                                
                                                userEntriesNode.removeObserver(withHandle: observeEntriesHandle)
                                            }
                                    })
                                    
                                    // Since .childAdded events for existing database entries will fire
                                    // before this .value event fires on userEntriesNode, we use the .value
                                    // event to determine when we have read all existing entries.
                                    userEntriesNode.observeSingleEvent(
                                        of: .value,
                                        with: { (snapshot: FIRDataSnapshot) in
                                            
                                            existingEntriesLoaded = true
                                            success()
                                        })
                                }
                                else {
                                    
                                    success()
                                }
                            })
                    }
                    else {
                        
                        success()
                    }
                })
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error observing entries. User undefined."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }
    
    // Resize the specified image for database storage.
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Create a rectangle representing the resized image.
        var newSize: CGSize
        if widthRatio > heightRatio {
            
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        }
        else {
            
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Resize the image.
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    // Create the storage node for the specified entry image.
    private func storeEntryImage(entryId: String, image: UIImage, success: @escaping (_ imageUrl: String) -> (), failure: @escaping (Error) -> ()) {
        
        let storageNode = FIRStorage.storage().reference()
        let entryImageNode = storageNode.child(Constants.Firebase.entryImagesKey).child("\(entryId).png")
        if let imageData = UIImagePNGRepresentation(image) {
            
            entryImageNode.put(
                imageData,
                metadata: nil,
                completion: { (metadata: FIRStorageMetadata?, error: Error?) in
                    
                    if let imageUrl = metadata?.downloadURL()?.absoluteString {
                        
                        success(imageUrl)
                    }
                    else {
                        
                        let userInfo = [NSLocalizedDescriptionKey : "Error storing entry image."]
                        failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
                    }
                })
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error getting entry image data."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }

    // Delete the storage node for the specified entry image.
    func deleteEntryImage(entryId: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        let storageNode = FIRStorage.storage().reference()
        let entryImageNode = storageNode.child(Constants.Firebase.entryImagesKey).child("\(entryId).png")
        entryImageNode.delete(
            completion: { (error: Error?) in
                
                if let error = error {
                    
                    failure(error)
                }
                else {
                    
                    success()
                }
            })
    }
}
