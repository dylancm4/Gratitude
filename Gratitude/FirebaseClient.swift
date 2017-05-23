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
    
    var isConnected = false
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
        
        // Enable disk persistence to maintain state while offline.
        FIRDatabase.database().persistenceEnabled = true
        
        // Track whether we are connected.
        let connectedNode = FIRDatabase.database().reference(withPath: Constants.Firebase.connectedPath)
        connectedNode.observe(
            .value,
            with: { snapshot in
            
                if let connected = snapshot.value as? Bool, connected {
                
                    self.isConnected = true
                }
                else {
                    
                    self.isConnected = false
                }
            })
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
    func createEntry(text: String, image: UIImage?, videoFileUrl: URL?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        // Firebase persistence does not work correctly for FIRStorage, so
        // error out if not connected.
        if (image != nil || videoFileUrl != nil) && !isConnected {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error creating entry. Network offline."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
            return
        }

        let funcSuccess = success
        let funcFailure = failure
        if let currentUserId = User.currentUser?.id {
            
            let rootNode = FIRDatabase.database().reference()
            let entryNode = rootNode.child(Constants.Firebase.entriesKey).child(currentUserId).childByAutoId()
            updateEntry(
                entryNode: entryNode,
                text: text,
                image: image,
                existingVideoUrl: nil,
                videoFileUrl: videoFileUrl,
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

    // Update the entry node for the specified entry. The isVideoEntry parameter indicates
    // whether the updated entry is a video entry.
    func updateEntry(originalEntry: Entry, text: String, image: UIImage?, isVideoEntry: Bool, videoFileUrl: URL?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
        // Firebase persistence does not work correctly for FIRStorage, so
        // error out if not connected.
        if (originalEntry.imageUrl != nil || originalEntry.videoUrl != nil || image != nil || videoFileUrl != nil) && !isConnected {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error updating entry. Network offline."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
            return
        }
        
        let funcSuccess = success
        let funcFailure = failure
        if let currentUserId = User.currentUser?.id {
            
            let entryId = originalEntry.id!
            let rootNode = FIRDatabase.database().reference()
            let entryNode = rootNode.child(Constants.Firebase.entriesKey).child(currentUserId).child(entryId)
            if originalEntry.imageUrl != nil {
                
                // Delete the storage node for the entry image.
                self.deleteEntryImage(
                    entryId: entryId,
                    success: {
                        
                        // If the user updated a video entry but did not select a new image
                        // or video, then isVideoEntry will be true but videoFileUrl will be
                        // nil. In this case, the existing video should not be deleted from
                        // Firebase storage.
                        if originalEntry.videoUrl != nil && !isVideoEntry {
                            
                            // Delete the storage node for the entry video.
                            self.deleteEntryVideo(
                                entryId: entryId,
                                success: {
                                    
                                    self.updateEntry(
                                        entryNode: entryNode,
                                        text: text,
                                        image: image,
                                        existingVideoUrl: nil,
                                        videoFileUrl: videoFileUrl,
                                        happinessLevel: happinessLevel,
                                        placemark: placemark,
                                        location: location,
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
                        else { // no existing video
                            
                            self.updateEntry(
                                entryNode: entryNode,
                                text: text,
                                image: image,
                                existingVideoUrl: originalEntry.videoUrl,
                                videoFileUrl: videoFileUrl,
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
                    },
                    failure: { (error: Error) in
                        
                        funcFailure(error)
                    })
            }
            else { // no existing image
                
                updateEntry(
                    entryNode: entryNode,
                    text: text,
                    image: image,
                    existingVideoUrl: originalEntry.videoUrl,
                    videoFileUrl: videoFileUrl,
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
        }
        else {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error updating entry. User undefined."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
        }
    }
    
    // Create/update the entry node for the specified entry.
    private func updateEntry(entryNode: FIRDatabaseReference, text: String, image: UIImage?, existingVideoUrl: URL?, videoFileUrl: URL?, happinessLevel: Int, placemark: String?, location: Location?, success: @escaping (_ entry: Entry) -> (), failure: @escaping (Error) -> ()) {
        
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
        else {
            
            values[Constants.Firebase.Entry.placemarkKey] = NSNull()
        }
        if let location = location {
            
            values[Constants.Firebase.Entry.locationKey] = location.dictionary
        }
        else {
            
            values[Constants.Firebase.Entry.locationKey] = NSNull()
        }
        
        if let image = image {
            
            // Resize the image
            let resizedImage = resizeImage(image: image, targetSize: CGSize.init(width: 600, height: 600))
            let aspectRatio = Double(resizedImage.size.width) / Double(resizedImage.size.height)
            
            // Create the storage node for the entry image.
            storeEntryImage(
                entryId: entryNode.key,
                image: resizedImage,
                success: { (imageUrl: URL) in
                    
                    values[Constants.Firebase.Entry.imageUrlKey] = imageUrl.absoluteString
                    values[Constants.Firebase.Entry.aspectRatioKey] = aspectRatio
                    
                    // Create the storage node for the entry video.
                    if let videoFileUrl = videoFileUrl {
                        
                        self.storeEntryVideo(
                            entryId: entryNode.key,
                            videoFileUrl: videoFileUrl,
                            success: { (videoUrl: URL) in
                                
                                values[Constants.Firebase.Entry.videoUrlKey] = videoUrl.absoluteString

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
                    else { // no video file
                        
                        // If there is an entry video and the storage node
                        // already exists, specify the video URL of the storage
                        // node.
                        if let existingVideoUrl = existingVideoUrl {
                            
                            values[Constants.Firebase.Entry.videoUrlKey] = existingVideoUrl.absoluteString
                        }
                        else {
                            
                            values[Constants.Firebase.Entry.videoUrlKey] = NSNull()
                        }
                    
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
                    }
                },
                failure: { (error: Error) in
                
                    funcFailure(error)
                })
        }
        else { // no image/video
            
            values[Constants.Firebase.Entry.imageUrlKey] = NSNull()
            values[Constants.Firebase.Entry.aspectRatioKey] = NSNull()
            values[Constants.Firebase.Entry.videoUrlKey] = NSNull()

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

        // Firebase persistence does not work correctly for FIRStorage, so
        // error out if not connected.
        if (entry.imageUrl != nil || entry.videoUrl != nil) && !isConnected {
            
            let userInfo = [NSLocalizedDescriptionKey : "Error deleting entry. Network offline."]
            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
            return
        }
        
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
                                    
                                    if entry.videoUrl != nil {
                                        
                                        // Delete the storage node for the entry video.
                                        self.deleteEntryVideo(
                                            entryId: entryId,
                                            success: {
                                                
                                                funcSuccess()
                                            },
                                            failure: { (error: Error) in
                                            
                                                funcFailure(error)
                                            })
                                    }
                                    else {
                                
                                        funcSuccess()
                                    }
                                },
                                failure: { (error: Error) in
                            
                                    funcFailure(error)
                                })
                        }
                        else {
                            
                            funcSuccess()
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
    private func storeEntryImage(entryId: String, image: UIImage, success: @escaping (_ imageUrl: URL) -> (), failure: @escaping (Error) -> ()) {
        
        let storageNode = FIRStorage.storage().reference()
        let entryImageNode = storageNode.child(Constants.Firebase.entryImagesKey).child("\(entryId).png")
        if let imageData = UIImagePNGRepresentation(image) {
            
            entryImageNode.put(
                imageData,
                metadata: nil,
                completion: { (metadata: FIRStorageMetadata?, error: Error?) in
                    
                    if let error = error {
                        
                        failure(error)
                    }
                    else {
                        
                        if let imageUrl = metadata?.downloadURL() {
                            
                            success(imageUrl)
                        }
                        else {
                            
                            let userInfo = [NSLocalizedDescriptionKey : "Error storing entry image."]
                            failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
                        }
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

    // Create the storage node for the specified entry video.
    private func storeEntryVideo(entryId: String, videoFileUrl: URL, success: @escaping (_ videoUrl: URL) -> (), failure: @escaping (Error) -> ()) {
        
        let storageNode = FIRStorage.storage().reference()
        let entryVideoNode = storageNode.child(Constants.Firebase.entryVideosKey).child("\(entryId).mov")
        entryVideoNode.putFile(
            videoFileUrl,
            metadata: nil,
            completion: { (metadata: FIRStorageMetadata?, error: Error?) in
                    
                if let error = error {
                        
                    failure(error)
                }
                else {
                        
                    if let videoUrl = metadata?.downloadURL() {
                            
                        success(videoUrl)
                    }
                    else {
                            
                        let userInfo = [NSLocalizedDescriptionKey : "Error storing entry video."]
                        failure(NSError(domain: "FirebaseClient", code: 1, userInfo: userInfo))
                    }
                }
            })
        // An enhancement would be to use the FIRStorageUploadTask return
        // value of putFile() and display some kind of percentage progress
        // indicator, though the app's "local" entry feature makes this
        // irrelevant.
    }
    
    // Delete the storage node for the specified entry video.
    func deleteEntryVideo(entryId: String, success: @escaping () -> (), failure: @escaping (Error) -> ()) {
        
        let storageNode = FIRStorage.storage().reference()
        let entryVideoNode = storageNode.child(Constants.Firebase.entryVideosKey).child("\(entryId).mov")
        entryVideoNode.delete(
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
