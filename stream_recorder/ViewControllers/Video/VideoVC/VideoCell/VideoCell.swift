//
//  VideoCell.swift
//  stream_recorder
//
//  Created by HHumorous on 05/04/2022.
//

import UIKit
import AVFoundation

class VideoCell: UICollectionViewCell {
    
    @IBOutlet weak var imgThumb: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    static let identifierCell = "VideoCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configura(video: VideoModel) {
        lblTitle.text = Int(video.duration).durationTimeToShortString()
        DispatchQueue.global().async {
            let asset = AVAsset(url: video.path)
            let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let time = CMTimeMake(value: 0, timescale: 1)
            let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            if let image = img {
                DispatchQueue.main.async {
                    self.imgThumb.image = UIImage(cgImage: image)
                }
            }
        }
    }
}
