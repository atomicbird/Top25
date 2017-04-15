//
//  FeedManager.swift
//  Top25
//
//  Created by Tom Harrington on 4/11/17.
//  Copyright © 2017 Atomic Bird LLC. All rights reserved.
//

import UIKit

class FeedEntry {
    var title : String?
    var artist : String?
    var releaseDate : String?
    var collection : String?
    var price : String?
    var category : String?
    var audioPreviewURL : String?
    var storeURL : String?
    var imageURL : String?
    var artistURL : String?
    var image : UIImage?
    var imageTask : URLSessionDataTask?
    
    let urlSession : URLSession
    
    init(entry:AnyObject, session:URLSession) {
        title = entry.value(forKeyPath: "title.label") as? String
        artist = entry.value(forKeyPath: "im:artist.label") as? String
        artistURL = entry.value(forKeyPath: "im:artist.attributes.href") as? String
        releaseDate = entry.value(forKeyPath: "im:releaseDate.label") as? String
        collection = entry.value(forKeyPath: "im:collection.im:name.label") as? String
        
        if let links = entry.value(forKeyPath: "link") as? Array<AnyObject> {
            for link in links {
                if let type = link.value(forKeyPath: "attributes.type") as? String,
                    let linkURL = link.value(forKeyPath: "attributes.href") as? String {
                    switch(type) {
                    case "audio/x-m4a":
                        audioPreviewURL = linkURL
                        break
                    case "text/html":
                        storeURL = linkURL
                        break
                    default:
                        break
                    }
                }
            }
        }

        if let imagesInfo = entry.value(forKeyPath: "im:image") as? NSArray {
            // Get the largest image available at whatever size
            var imageHeight = 0
            for imageInfo in imagesInfo {
                if let heightString = (imageInfo as AnyObject).value(forKeyPath: "attributes.height") as? String, 
                    let height = Int(heightString), height > imageHeight,
                    let imageURL = (imageInfo as AnyObject).value(forKeyPath: "label") as? String {
                    imageHeight = height
                    self.imageURL = imageURL
                }
            }
        }
        if let price = entry.value(forKeyPath: "im:price.label") as? String { self.price = price }
        if let category = entry.value(forKeyPath: "category.attributes.label") as? String { self.category = category }
        
        urlSession = session
    }
    
    func fetchImage(completion: @escaping (Bool) -> ()) -> Void {
        guard image == nil else {
            return
        }
        guard self.imageTask == nil else {
            return
        }
        guard let imageURLString = self.imageURL,
            let imageURL = URL(string:imageURLString) else {
                return
        }
        
        let imageTask = URLSession.shared.dataTask(with: imageURL) { (data:Data?, response:URLResponse?, error: Error?) in
            if let error = error {
                print("Image load error: \(error)")
            }
            guard let imageData = data,
                let newImage = UIImage(data: imageData) else {
                    return
            }
            print("Image downloaded")
            self.image = newImage
            completion(true)
        } 
        self.imageTask = imageTask
        imageTask.resume()
    }
    
    func cancelFetchImage() -> Void {
        imageTask?.cancel()
        imageTask = nil
    }
}

class FeedManager {
    // URL is from https://rss.itunes.apple.com/us/?urlDesc=%2Fgenerator
    // Change "xml" to "json" on generated URLs to get JSON.
    static let urlString = "https://itunes.apple.com/us/rss/topsongs/limit=25/json"
    
    var feedEntries = [FeedEntry]()
    let urlSession : URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration)
    }
    
    func reloadFeed(completion:  @escaping (Bool) -> ()) -> Void {
        guard let url = URL(string: FeedManager.urlString) else {
            return
        }
        
        let task = urlSession.dataTask(with: url, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var success = false
            
            self.feedEntries.removeAll()
            //                URLSession.shared.reset {}
            
            defer {
                print("Loaded \(self.feedEntries.count) items")
                completion(success)
            }
            
            guard let jsonData = data else {
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as? NSDictionary,
                    let entries = json.value(forKeyPath: "feed.entry") as? NSArray else {
                        return
                }
                entries.forEach { (entry) in
                    let feedEntry = FeedEntry(entry: entry as AnyObject, session:self.urlSession)
                    self.feedEntries.append(feedEntry)
                }
                success = true
            } catch {
                
            }
        })
        task.resume()
    }

    func fetchImageAtIndex(index:Int, completion:@escaping (Int) -> ()) -> Void {
        guard index < feedEntries.count else {
            return
        }
        
        feedEntries[index].fetchImage { (success) in
            if success {
                completion(index)
            }
        }
    }
    
    func cancelFetchImageAtIndex(index:Int) -> Void {
        guard index < feedEntries.count else {
            return
        }
        
        feedEntries[index].cancelFetchImage()
    }
}
