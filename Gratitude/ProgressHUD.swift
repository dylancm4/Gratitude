//
//  ProgressHUD.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/7/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit
import MBProgressHUD

class ProgressHUDView: UIView {
    
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        setup()
    }
    
    override var intrinsicContentSize: CGSize {
        
        return CGSize(width: imageView.bounds.width, height: imageView.bounds.height)
    }
    
    private func setup() {
        
        imageView = UIImageView(image: UIImage(named: Constants.ImageName.reallyHappy))
        imageView.alpha = 0.8
        addSubview(imageView)
        
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.repeatCount = Float.infinity
        imageView.layer.add(rotateAnimation, forKey: nil)
    }
}

class ProgressHUD: MBProgressHUD {
    
    override init(view: UIView) {
        
        super.init(view: view)
        
        bezelView.style = .solidColor
        bezelView.backgroundColor = UIColor.clear
        mode = .customView
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    override func show(animated: Bool) {
     
        customView = ProgressHUDView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        super.show(animated: animated)
    }
    
    override func hide(animated: Bool) {
    
        super.hide(animated: animated)
        customView = nil
    }
}
