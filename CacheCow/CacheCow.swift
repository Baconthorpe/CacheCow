//
//  CacheCow.swift
//  CacheCow
//
//  Created by Ezekiel Abuhoff on 6/22/17.
//  Copyright © 2017 Ezekiel Abuhoff. All rights reserved.
//

import UIKit

public class ImageCache {
    // MARK: Singleton
    fileprivate static let shared = ImageCache()
    
    // MARK: Instance Properties
    private var urlToImage: [String : UIImage] = [:]
    private var privateDefaultImage: UIImage?
    
    public var defaultImage: UIImage {
        get {
            if let presentDefaultImage = privateDefaultImage {
                return presentDefaultImage
            }
            
            let blankImage = UIImage()
            privateDefaultImage = blankImage
            return blankImage
        }
        
        set(newDefaultImage) {
            privateDefaultImage = newDefaultImage
        }
    }
    public var shouldLogErrors = false
    
    // MARK: Image Retrieval and Storage
    public static func getImage(from url: String, completion: @escaping (UIImage) -> ()) {
        shared.getImage(from: url, completion: completion)
    }
    
    public static func store(image newImage: UIImage, url: String) {
        shared.store(image: newImage, url: url)
    }
    
    public func getImage(from url: String, completion: @escaping (UIImage) -> ()) {
        if let cachedImage = urlToImage[url] {
            OperationQueue.main.addOperation {
                completion(cachedImage)
            }
        } else {
            ImageCache.retrieveImage(from: url, completion: { (image, error) in
                if let presentError = error {
                    self.handle(imageError: presentError)
                    OperationQueue.main.addOperation {
                        completion(self.defaultImage)
                    }
                }
                if let presentImage = image {
                    OperationQueue.main.addOperation {
                        completion(presentImage)
                    }
                }
            })
        }
    }
    
    public func store(image newImage: UIImage, url: String) {
        urlToImage[url] = newImage
    }
    
    // MARK: Network Call
    private static func retrieveImage(from url: String, completion: @escaping (UIImage?, ImageCacheError?) -> ()) {
        guard let verifiedURL = URL(string: url) else { completion(nil, .invalidURL); return }
        
        let task = URLSession.shared.dataTask(with: verifiedURL) { (data, response, error) in
            guard error == nil else { print("ERROR: \(String(describing: error))"); completion(nil, .failureResponse); return }
            guard let data = data else { completion(nil, .couldNotParseData); return }
            guard let image = UIImage(data: data) else { completion(nil, .couldNotParseData); return }
            
            completion(image, nil)
        }
        
        task.resume()
    }
    
    // MARK: Error Handling
    private func handle(imageError: ImageCacheError) {
        if shouldLogErrors {
            switch imageError {
            case .invalidURL:
                print("Image Caching Error: Image URL was invalid.")
            case .failureResponse:
                print("Image Caching Error: Request for image data failed.")
            case .couldNotParseData:
                print("Image Caching Error: Image data retrieved could not be parsed.")
            }
        }

    }
}

public enum ImageCacheError: Error {
    case invalidURL
    case failureResponse
    case couldNotParseData
}

public class ImageCacheView: UIImageView {
    // MARK: Instance Properties
    public var cache: ImageCache?
    public var inProgressImage: UIImage?
    
    private var currentURL: String?
    
    // MARK: Loading Images
    public func loadImage(url: String) {
        let chosenCache = cache ?? ImageCache.shared
        privateLoadImage(url: url, cache: chosenCache)
    }
    
    public func loadImage(url: String, cache chosenCache: ImageCache) {
        privateLoadImage(url: url, cache: chosenCache)
    }
    
    private func privateLoadImage(url: String, cache chosenCache: ImageCache) {
        currentURL = url
        if let presentInProgressImage = inProgressImage {
            image = presentInProgressImage
        }
        
        chosenCache.getImage(from: url, completion: { (newImage) in
            if url == self.currentURL {
                self.image = newImage
            }
        })
    }
}
