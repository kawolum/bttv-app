//
//  ChannelTableViewCell.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/5/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class ChannelUITableViewCell: UITableViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    internal var aspectConstraint : NSLayoutConstraint? {
        didSet {
            if oldValue != nil {
                previewImage.removeConstraint(oldValue!)
            }
            if aspectConstraint != nil {
                previewImage.addConstraint(aspectConstraint!)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        label1.layer.shadowOffset = CGSize(width: 0, height: 0)
        label1.layer.shadowOpacity = 1
        label1.layer.shadowRadius = 10
        label2.layer.shadowOffset = CGSize(width: 0, height: 0)
        label2.layer.shadowOpacity = 1
        label2.layer.shadowRadius = 10
        label3.layer.shadowOffset = CGSize(width: 0, height: 0)
        label3.layer.shadowOpacity = 1
        label3.layer.shadowRadius = 10
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        aspectConstraint = nil
    }
    
    func setPostedImage(image : UIImage) {
        
        let aspect = image.size.width / image.size.height
        
        aspectConstraint = NSLayoutConstraint(item: previewImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: previewImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
        
        previewImage.image = image
    }
}
