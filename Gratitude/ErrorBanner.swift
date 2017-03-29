//
//  ErrorBanner.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class ErrorBanner {
    
    static func presentError(message: String, inView view: UIView) {
        
        view.layer.removeAllAnimations()
        
        let errorBanner = UIView()
        let errorBannerWidth = UIScreen.main.bounds.width
        let errorBannerHeight: CGFloat = 60
        errorBanner.frame = CGRect(x: 0, y: -errorBannerHeight, width: errorBannerWidth, height: errorBannerHeight)
        errorBanner.backgroundColor = Constants.Color.errorBanner

        let errorMessage = UILabel()
        errorMessage.frame = errorBanner.bounds
        errorMessage.text = message
        errorMessage.textColor = Constants.Color.offWhite
        errorMessage.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightRegular)
        errorMessage.textAlignment = .center
        
        errorBanner.addSubview(errorMessage)
        view.addSubview(errorBanner)
        
        UIView.animate(
            withDuration: 1,
            animations: {
            
                errorBanner.center.y = errorBanner.center.y + errorBannerHeight
            },
            completion: {(value: Bool) in
            
                UIView.animate(withDuration: 1, delay: 4, options: [], animations: {
                
                    errorBanner.center.y = errorBanner.center.y - errorBannerHeight
                
                },
                completion: { (value: Bool) in
                
                    errorBanner.removeFromSuperview()
                })
            })
    }
}
