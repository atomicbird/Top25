//
//  FeedManager.swift
//  XMLTest1
//
//  Created by Tom Harrington on 7/11/16.
//  Copyright © 2016 Atomic Bird. All rights reserved.
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
    
    init(entry:AnyObject) {
        if let title = entry.value(forKeyPath: "title.label") as? String { self.title = title }
        if let artist = entry.value(forKeyPath: "im:artist.label") as? String { self.artist = artist }
        if let artistURL = entry.value(forKeyPath: "im:artist.attributes.href") as? String { self.artistURL = artistURL }
        if let releaseDateString = entry.value(forKeyPath: "im:releaseDate.label") as? String { self.releaseDate = releaseDateString }
        if let collection = entry.value(forKeyPath: "im:collection.im:name.label") as? String { self.collection = collection }
        if let links = entry.value(forKeyPath: "link") as? NSArray {
            for link in links {
                if let type = link.value(forKeyPath: "attributes.type") as? String,
                    let linkURL = link.value(forKeyPath: "attributes.href") as? String {
                    switch(type) {
                    case "audio/x-m4a":
                        self.audioPreviewURL = linkURL
                        break
                    case "text/html":
                        self.storeURL = linkURL
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
                if let heightString = imageInfo.value(forKeyPath: "attributes.height") as? String, 
                    let height = Int(heightString), height > imageHeight,
                    let imageURL = imageInfo.value(forKeyPath: "label") as? String {
                    imageHeight = height
                    self.imageURL = imageURL
                }
            }
        }
        if let price = entry.value(forKeyPath: "im:price.label") as? String { self.price = price }
        if let category = entry.value(forKeyPath: "category.attributes.label") as? String { self.category = category }
    }
    
    func fetchImage(completion: (Bool) -> ()) -> Void {
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
        
        let imageTask = URLSession.shared.dataTask(with: imageURL) { (data:Data?, response:URLResponse?, error:NSError?) in
            if let error = error, error.code != -999, error.domain != NSURLErrorDomain {
                // Print the error unless it's a -999, which happens when the task is canceled.
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
    
    func reloadFeed(completion: (Bool) -> ()) -> Void {
        if let url = URL(string: FeedManager.urlString) {
            
            let task = URLSession.shared.dataTask(with: url, completionHandler: { (data:Data?, response:URLResponse?, error:NSError?) in
                var success = false
                
                self.feedEntries.removeAll()
                URLSession.shared.reset {}
                
                defer {
                    print("Loaded \(self.feedEntries.count) items")
                    completion(success)
                }
                
                guard let jsonData = data else {
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as? NSDictionary,
                        let entries = json.value(forKeyPath: "feed.entry") as? NSArray
                    {
                        for entry in entries {
                            let feedEntry = FeedEntry(entry: entry)
                            self.feedEntries.append(feedEntry)
                        }
                        success = true
                    }
                } catch {
                    
                }
            })
            task.resume()
        }
    }

    func fetchImageAtIndex(index:Int, completion:(Int) -> ()) -> Void {
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
