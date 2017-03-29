
//  ViewEntryTableViewCell.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class ViewEntryTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var happinessImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var entryImageView: UIImageView!
    
    var entryImageViewAspectConstraint : NSLayoutConstraint? {
        
        didSet {
            
            if let oldAspectConstraint = oldValue {
                
                entryImageView.removeConstraint(oldAspectConstraint)
            }
            if let aspectConstraint = entryImageViewAspectConstraint {
                
                aspectConstraint.priority = 999 // avoid LayoutConstraints error
                entryImageView.addConstraint(aspectConstraint)
            }
        }
    }
    
    var entry: Entry?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
        textView.textContainer.lineBreakMode = .byTruncatingTail
        locationImageView.image = locationImageView.image?.withRenderingMode(.alwaysTemplate)
        entryImageView.layer.cornerRadius = 3
        entryImageView.clipsToBounds = true
    }

    // Set the cell contents based on the specified parameters.
    func setData(entry: Entry) {
        
        self.entry = entry
        
        if let happinessLevel = entry.happinessLevel {
            
            happinessImageView.image = Entry.getHappinessLevelImage(happinessLevel)
        }
        else {
            
            happinessImageView.image = nil
        }
        
        if let createdDate = entry.createdDate {
            
            dateLabel.text = Constants.dateString(from: createdDate)
        }
        else {
            
            dateLabel.text = nil
        }

        textView.text = entry.text
        
        if let placemark = entry.placemark {
            
            locationLabel.text = placemark
            locationImageView.isHidden = false
        }
        else {
            
            locationLabel.text = nil
            locationImageView.isHidden = true
        }
        
        if entry.isLocal {
            
            if let localImage = entry.localImage {
                
                setEntryImageViewAspectConstraint(hasImage: true, aspectRatio: entry.aspectRatio)
                entryImageView.image = localImage
            }
            else {
                
                setEntryImageViewAspectConstraint(hasImage: false, aspectRatio: nil)
                entryImageView.image = nil
            }
        }
        else {

            if let imageUrl = entry.imageUrl {
                
                setEntryImageViewAspectConstraint(hasImage: true, aspectRatio: entry.aspectRatio)
                AlamofireClient.shared.downloadImage(
                    urlString: imageUrl,
                    success: { (image: UIImage) in
                        
                        DispatchQueue.main.async {
                            
                            self.entryImageView.image = image
                        }
                    },
                    failure: { (error: Error) in
                        
                    })
            }
            else {
                
                setEntryImageViewAspectConstraint(hasImage: false, aspectRatio: nil)
                entryImageView.image = nil
            }
        }
    }
    
    // Set the entryImageView aspect ratio constraint based on the image.
    func setEntryImageViewAspectConstraint(hasImage: Bool, aspectRatio: Double?) {
        
        if hasImage {
            
            // Create entryImageView aspect ratio constraint to match
            // image aspect ratio.
            let aspect: CGFloat = CGFloat(aspectRatio ?? (4.0 / 3.0))
            entryImageViewAspectConstraint = NSLayoutConstraint(
                item: entryImageView,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: entryImageView,
                attribute: NSLayoutAttribute.height,
                multiplier: aspect,
                constant: 0.0)
        }
        else {
            
            // No image, create entryImageView height constraint of 0 so
            // that it has no effect on auto layout.
            self.entryImageViewAspectConstraint = NSLayoutConstraint(
                item: entryImageView,
                attribute: NSLayoutAttribute.height,
                relatedBy: NSLayoutRelation.equal,
                toItem: nil,
                attribute: NSLayoutAttribute.notAnAttribute,
                multiplier: 1,
                constant: 0)
        }
    }
}
