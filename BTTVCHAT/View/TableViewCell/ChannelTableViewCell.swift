//
//  ChannelTableViewCell.swift
//  BTTVCHAT
//
//  Created by Ka Lum on 1/5/17.
//  Copyright © 2017 Ka Lum. All rights reserved.
//

import UIKit

class ChannelTableViewCell: UITableViewCell {
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
        setAspectConstraint()
    }
    
    func setPostedImage(image : UIImage) {
        previewImage.image = image
        setAspectConstraint()
    }
    
    func setAspectConstraint(){
        if let image = previewImage.image{
            let aspect = image.size.width / image.size.height
            aspectConstraint = NSLayoutConstraint(item: previewImage, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: previewImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
        }
    }
}
