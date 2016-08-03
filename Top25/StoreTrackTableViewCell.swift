//
//  StoreTrackTableViewCell.swift
//  Top25
//
//  Created by Tom Harrington on 8/2/16.
//  Copyright © 2016 Atomic Bird. All rights reserved.
//

import UIKit

class StoreTrackTableViewCell: UITableViewCell {
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackArtistLabel: UILabel!
    @IBOutlet weak var trackAlbumArtworkView: UIImageView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var playProgressView: UIProgressView!
    @IBOutlet weak var playbackTime: UILabel!
    @IBOutlet weak var audioPlaybackView: UIView! {
        didSet {
            audioPlaybackView.isHidden = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
