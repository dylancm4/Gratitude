//
//  AlamofireClient.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/27/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

// Class which uses Alamofire to download and cache images.
class AlamofireClient {
    
    // Shared instance.
    static var shared = AlamofireClient()
    
    let imageDownloader = ImageDownloader(
        configuration: ImageDownloader.defaultURLSessionConfiguration(),
        downloadPrioritization: .fifo,
        maximumActiveDownloads: 4,
        imageCache: AutoPurgingImageCache())
    
    // Download the specified image.
    func downloadImage(url: URL, success: @escaping (_ image: UIImage) -> (), failure: @escaping (Error) -> ()) {
        
        let urlRequest = URLRequest(url: url)
        imageDownloader.download(urlRequest) { response in
            
            if let afError = response.error {
                
                failure(afError)
            }
            else if let image = response.result.value {
                
                success(image)
            }
            else {
                
                let userInfo = [NSLocalizedDescriptionKey : "Error downloading image."]
                failure(NSError(domain: "AlamofireClient", code: 1, userInfo: userInfo))
            }
        }
    }
}
