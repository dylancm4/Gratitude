//
//  SettingsIconTableViewCell.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class SettingsIconTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        // Initialization code
        iconImageView.tintColor = Constants.Color.darkTeal
    }
    
    // Set the cell contents based on the specified parameters.
    func setData(imageName: String?, title: String?)
    {
        if let imageName = imageName {
            
            iconImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        }
        else {
            
            iconImageView.image = nil
        }
        titleLabel.text = title
    }
}
