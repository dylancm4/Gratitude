//
//  EditEntryViewController.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import AVFoundation

class EditEntryViewController: ViewControllerBase, UIScrollViewDelegate, UITextViewDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var locationIconImageView: UIImageView!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var feelingImageView: UIImageView!
    @IBOutlet weak var feelingSlider: UISlider!
    
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var videoPlayButton: UIButton!
    
    var videoPlayUrl: URL?
    var videoFileUrl: URL?

    let locationManager = CLLocationManager()
    var placeOfInterest:String?
    
    var entry: Entry? {
        
        didSet {
            
            entryExisting = true
        }
    }
    // Whether this entry is already saved to the database. If true, update instead of create entry.
    var entryExisting = false
    
    var textViewPlaceholderText = "I'm grateful for..."
    
    // The view y right before keyboard is shown
    var topY: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    
    deinit {
        
        // Remove all of this object's observer entries.
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set up the navigation bar.
        if let navigationController = navigationController {
            
            // Set the navigation bar background color.
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.barTintColor = Constants.Color.darkTeal
            
            // Set the navigation bar text and icon color.
            navigationController.navigationBar.tintColor = Constants.Color.offWhite
            navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Constants.Color.lightTeal]
            
            // Set title.
            if entry == nil {
                
                navigationItem.title = "New Entry"
            }
            else {
                
                navigationItem.title = "Edit Entry"
            }
        }
        
        // Navigation bar save button.
        let saveButton = UIBarButtonItem(
            image: UIImage(named: Constants.ImageName.saveButton), style: .plain, target: self, action: #selector(EditEntryViewController.saveEntry))
        navigationItem.rightBarButtonItem = saveButton
        
        // Navigation bar cancel button.
        let cancelButton = UIBarButtonItem(
            image: UIImage(named: Constants.ImageName.cancelButton), style: .plain, target: self, action: #selector(EditEntryViewController.cancelEntry))
        navigationItem.leftBarButtonItem = cancelButton
        
        // Ask for location permission
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Hide keyboard on tap outside of text fields
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EditEntryViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Location Icon
        locationIconImageView.image = locationIconImageView.image?.withRenderingMode(.alwaysTemplate)
        
        // Style text view
        textView.layer.cornerRadius = 3.0
        textView.clipsToBounds = true
        
        // Image button
        uploadImageButton.imageView?.contentMode = .scaleAspectFit
        
        // Video play button
        videoPlayButton.setImage(videoPlayButton.currentImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        // If new entry, use current date.
        if entry == nil {
            
            dateLabel.text = Constants.dateString(from: Date())
            
            // Placeholder entry text
            textView.text = textViewPlaceholderText
            textView.textColor = UIColor.lightGray
            textView.delegate = self
        }
        
        // If editing an existing entry, show values of that entry.
        if let entry = entry {
            
            if let date = entry.createdDate {
                
                dateLabel.text = Constants.dateString(from: date)
            }
            if let text = entry.text {
                
                textView.text = text
            }
            if let locationName = entry.placemark {
                
                locationTextField.text = locationName
            }
            if let happinessLevel = entry.happinessLevel {
                
                feelingImageView.image = Entry.getHappinessLevelImage(happinessLevel)
                feelingSlider.value = Float(Entry.getHappinessLevelInt(happinessLevel: happinessLevel))
            }
            if let imageUrl = entry.imageUrl {
                
                AlamofireClient.shared.downloadImage(
                    url: imageUrl,
                    success: { (image: UIImage) in
                        
                        DispatchQueue.main.async {
                            
                            self.uploadImageButton.setImage(image, for: .normal)
                            if let uploadImageView = self.uploadImageButton.imageView {
                                
                                Constants.setRoundCornersForAspectFit(imageView: uploadImageView, radius: 3.0)
                            }
                        }
                    },
                    failure: { (error: Error) in
                        
                        DispatchQueue.main.async {
                        
                            // Display placeholder image if there is an error
                            // loading the image.
                            self.uploadImageButton.setImage(UIImage(named: Constants.ImageName.imagePlaceholder), for: .normal)
                        }
                    })
            }
            if let entryVideoUrl = entry.videoUrl {
                
                videoPlayUrl = entryVideoUrl
            }
            else {
                
                videoPlayUrl = nil
            }
        }
        else {
            
            videoPlayUrl = nil
        }
        videoFileUrl = nil
        
        videoPlayButton.isHidden = videoPlayUrl == nil
        
        if let locationCoordinate = locationManager.location?.coordinate {
            
            willRequest()

            // First show Google Maps state and city, and then try reverse
            // geocoding to try Apple maps for placemarks.
            placeOfInterest = GoogleMapsClient.shared.getAddressDescription(latitude: Float(locationCoordinate.latitude), longitude: Float(locationCoordinate.longitude))
            locationTextField.placeholder = placeOfInterest
            
            AppleMapsClient.shared.getAreaOfInterest(
                location: locationManager.location!,
                completion: {(areaOfInterest: String?, error: Error?) -> Void in
                    
                    self.requestDidSucceed(error == nil)
                
                    if error == nil, let areaOfInterest = areaOfInterest {
                        
                        self.placeOfInterest = areaOfInterest
                        self.locationTextField.placeholder = self.placeOfInterest
                    }
                })
        }
    }
    
    func getLocationObject() -> Location {
        
        let location = Location()
        location.name = locationTextField.text
        if let coordinate = locationManager.location?.coordinate {
            
            location.latitude = Float(coordinate.latitude)
            location.longitude = Float(coordinate.longitude)
        }
        return location
    }
    
    func cancelEntry() {
        
        self.dismiss(animated: true, completion: {})
    }
    
    // Create new entry.
    func saveEntry() {
        
        dismissKeyboard()
        
        if entryExisting {
            
            updateEntry()
        }
        else {
            
            var image: UIImage? = nil
            if uploadImageButton.image(for: .normal) != UIImage.init(named: Constants.ImageName.camera) {
                
                image = uploadImageButton.image(for: .normal)!
            }
            
            let placemark: String?
            if let locationText = locationTextField.text, !locationText.isEmpty {
                
                placemark = locationText
            }
            else {
                
                placemark = placeOfInterest
            }
            
            // Dismiss the view controller before creating the entry.
            dismiss(
                animated: true,
                completion: {
                    EntryBroker.shared.createEntry(
                        text: self.textView.text,
                        image: image,
                        videoFileUrl: self.videoFileUrl,
                        happinessLevel: Int(self.feelingSlider.value),
                        placemark: placemark,
                        location: self.getLocationObject())
                })
        }
    }
    
    // Update existing entry.
    func updateEntry() {
        
        var image: UIImage? = nil
        if uploadImageButton.image(for: .normal) != UIImage.init(named: Constants.ImageName.camera) {
            
            image = uploadImageButton.image(for: .normal)!
        }
        
        // Dismiss the view controller before updating the entry.
        dismiss(
            animated: true,
            completion: {
                EntryBroker.shared.updateEntry(
                    originalEntry: self.entry!,
                    text: self.textView.text,
                    image: image,
                    videoFileUrl: self.videoFileUrl,
                    isVideoEntry: self.videoPlayUrl != nil,
                    happinessLevel: Int(self.feelingSlider.value),
                    placemark: self.locationTextField.text,
                    location: self.getLocationObject())
            })
    }
    
    @IBAction func onUploadButton(_ sender: Any) {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        let optionMenu = UIAlertController(title: nil, message: "Please choose a photo source", preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(
            title: "Camera",
            style: .default,
            handler: { (action) -> Void in
                
                picker.sourceType = .camera
                self.present(picker, animated: true)
            })
        let albumOption = UIAlertAction(
            title: "Photo Album",
            style: .default,
            handler: { (action) -> Void in
                
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true)
            })
        let cancelOption = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action) -> Void in
            })
        optionMenu.addAction(cameraOption)
        optionMenu.addAction(albumOption)
        optionMenu.addAction(cancelOption)
        present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func onFeelingSliderChange(_ sender: UISlider) {
        
        let happinessLevelInt = Int(feelingSlider.value)
        let happinessLevel = Entry.getHappinessLevel(happinessLevelInt: happinessLevelInt)
        let feelingImage = Entry.getHappinessLevelImage(happinessLevel)
        if feelingImageView.image != feelingImage {
            
            UIView.transition(
                with: feelingImageView,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: { self.feelingImageView.image = feelingImage },
                completion: nil)
        }
    }
    
    @IBAction func onVideoPlayButton(_ sender: UIButton) {
                
        if let videoPlayUrl = videoPlayUrl {
            
            // Present the AVPlayerViewController for the video.
            presentVideoPlayerViewController(forVideoUrl: videoPlayUrl)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        videoFileUrl = info[UIImagePickerControllerMediaURL] as? URL
        if let videoFileUrl = videoFileUrl {
            
            videoPlayUrl = videoFileUrl

            if let thumbnailImage = getThumbnailImage(forVideoFileUrl: videoFileUrl) {
                
                uploadImageButton.setImage(thumbnailImage, for: .normal)
            }
        }
        else {
        
            videoPlayUrl = nil
            
            let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            uploadImageButton.setImage(chosenImage, for: .normal)
        }
        videoPlayButton.isHidden = videoPlayUrl == nil
        
        if let uploadImageView = uploadImageButton.imageView {
            
            Constants.setRoundCornersForAspectFit(imageView: uploadImageView, radius: 3.0)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func getThumbnailImage(forVideoFileUrl videoFileUrl: URL) -> UIImage? {
        
        let imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: videoFileUrl))
        
        do {
            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
        }
        catch {
            
            // Use placeholder image if there is an error generating
            // the thumbnail image.
            return UIImage(named: Constants.ImageName.imagePlaceholder)
        }
    }
    
    // MARK: - Notifications
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if keyboardSize.height > 0 {
                
                keyboardHeight = keyboardSize.height
                if topY == 0 {
                    
                    topY = self.view.frame.origin.y
                }
                if view.frame.origin.y != topY - keyboardHeight {
                    
                    view.frame.origin.y = topY - keyboardHeight
                }
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            if keyboardSize.height > 0 {
                
                if view.frame.origin.y != topY {
                    
                    view.frame.origin.y = topY
                }
            }
        }
    }
    
    func dismissKeyboard() {
        
        // Causes the view (or one of its embedded text fields) to resign the
        // first responder status.
        view.endEditing(true)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if !entryExisting {
            
            if textView.textColor == UIColor.lightGray {
                
                textView.text = nil
                textView.textColor = UIColor.darkGray
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if !entryExisting {
            
            if textView.text.isEmpty {
                
                textView.text = textViewPlaceholderText
                textView.textColor = UIColor.lightGray
            }
        }
    }
}
