//
//  TimelineTableViewCell.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

protocol TimelineTableViewCellDelegate: class {
    
    func timelineCellWasTapped(_ cell: TimelineTableViewCell)
}

class TimelineTableViewCell: UITableViewCell {

    @IBOutlet weak var monthNameLabel: UILabel!
    @IBOutlet weak var dayNameLabel: UILabel!
    @IBOutlet weak var dayNumberLabel: UILabel!
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
    weak var delegate : TimelineTableViewCellDelegate?
    let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
        textView.textContainer.lineBreakMode = .byTruncatingTail
        locationImageView.image = locationImageView.image?.withRenderingMode(.alwaysTemplate)
        entryImageView.layer.cornerRadius = 3
        entryImageView.clipsToBounds = true

        // Add a gesture recogizer programatically, since the following
        // error occurs otherwise: "invalid nib registered for identifier
        // (XXXCell) - nib must contain exactly one top level object which
        // must be a UITableViewCell instance."
        let tapGestureRecognizer =
            UITapGestureRecognizer(target: self, action: #selector(TimelineTableViewCell.onTextViewTap))
        tapGestureRecognizer.cancelsTouchesInView = true
        tapGestureRecognizer.numberOfTapsRequired = 1
        textView.addGestureRecognizer(tapGestureRecognizer)
    }

    @IBAction func onTextViewTap(_ sender: UITapGestureRecognizer) {
        
        // We use a tap gesture recognizer for the text view, since
        // otherwise taps on the UITextView will not register as selecting
        // a cell.
        if sender.state == .ended
        {
            if let delegate = delegate
            {
                delegate.timelineCellWasTapped(self)
            }
        }
    }

    // Set the cell contents based on the specified parameters.
    func setData(entry: Entry, delegate: TimelineTableViewCellDelegate) {
        
        self.entry = entry
        self.delegate = delegate
        
        if let happinessLevel = entry.happinessLevel {
        
            happinessImageView.image = Entry.getHappinessLevelImage(happinessLevel)
        }
        else {
        
            happinessImageView.image = nil
        }
        
        if let createdDate = entry.createdDate {
            
            let month = Calendar.current.component(.month, from: createdDate)
            monthNameLabel.text = monthNames[month-1]

            let day = Calendar.current.component(.day, from: createdDate)
            dayNumberLabel.text = String(format: "%02d", day)

            let weekday = Calendar.current.component(.weekday, from: createdDate)
            dayNameLabel.text = dayNames[weekday-1]            
        }
        else {
        
            dayNameLabel.text = nil
            dayNumberLabel.text = nil
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
                entryImageView.image = nil
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
        
        // Hide cells for which the entry is marked for deletion. Note that this
        // only hides the content of the cell, it does not change the cell height.
        isHidden = entry.isLocal && entry.isLocalMarkedForDelete
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
