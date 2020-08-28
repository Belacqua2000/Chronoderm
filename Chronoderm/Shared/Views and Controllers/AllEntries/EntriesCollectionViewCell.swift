//
//  EntriesCollectionViewCell.swift
//  Chronoderm
//
//  Created by Nick Baughan on 25/03/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit

class EntriesCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var cellImageView: UIImageView!
    @IBOutlet var cellDateLabel: UILabel!
    @IBOutlet var cellEntryLabel: UILabel!
    
    @IBOutlet var addEntryImageView: UIImageView!
    @IBOutlet var newEntryLabel: UILabel!
    
    func configure(with entry: Entry) {
        let df = DateFormatter()
        df.dateStyle = .short
        cellDateLabel.text = df.string(from: entry.date)
        
        if let attachment = entry.image?.anyObject() as? Attachment {
            if let imageData = attachment.fullImage?.fullImage {
                cellImageView.image = UIImage(data: imageData)
            }
        }
    }
    
}
