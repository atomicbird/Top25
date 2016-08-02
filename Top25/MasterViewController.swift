//
//  MasterViewController.swift
//  Top25
//
//  Created by Tom Harrington on 8/2/16.
//  Copyright © 2016 Atomic Bird. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UITableViewDataSourcePrefetching {

    let feedManager = FeedManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        let reloadButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(MasterViewController.reloadFeed))
        self.navigationItem.rightBarButtonItem = reloadButton
        
        tableView.prefetchDataSource = self

        reloadFeed()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reloadFeed() {
        feedManager.reloadFeed { (success) in
            print("success: \(success)")
            if success {
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
        }
    }

    func handleImageLoadForIndex(index:Int) -> Void {
        DispatchQueue.main.async { 
            let indexPath = IndexPath(row: index, section: 0)
            if let _ = self.tableView.cellForRow(at: indexPath) {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedManager.feedEntries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let feedEntry = feedManager.feedEntries[indexPath.row]
        cell.textLabel?.text = feedEntry.title
        cell.detailTextLabel?.text = feedEntry.artist
        
        if let image = feedEntry.image {
            cell.imageView?.image = image
        } else {
            feedManager.fetchImageAtIndex(index: indexPath.row, completion: { (index) in
                self.handleImageLoadForIndex(index: index)
            })
        }

        return cell
    }

    // MARK: - UITableViewDataSourcePrefetching
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("Prefetching rows \(indexPaths)")
        indexPaths.forEach { self.feedManager.fetchImageAtIndex(index: $0.row) {(index) in } }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("Cancelling prefetch for rows \(indexPaths)")
        indexPaths.forEach { self.feedManager.cancelFetchImageAtIndex(index: $0.row) }
    }
}

