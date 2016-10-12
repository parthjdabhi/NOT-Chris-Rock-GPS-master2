//
//  BusinessTableViewCell.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 10/12/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SDWebImage

class BusinessTableViewCell: UITableViewCell {

    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    @IBOutlet weak var reviewLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var dealsImage: UIImageView!
    
    var business: Business! {
        didSet {
            if business.imageURL != nil {
                previewImage.alpha = 1.0
                //                UIView.animateWithDuration(0.3, animations: {
                //                    self.restaurantImageView.setImageWithURL(self.business.imageURL!)
                //                    self.restaurantImageView.alpha = 1.0
                //                    }, completion: nil)
                
                previewImage.sd_setImageWithURL(self.business.imageURL!)
                
            } else {
                previewImage.image = UIImage(named: "noImage")
            }
            nameLabel.text = business?.name
            distanceLabel.text = business?.distance
            ratingImage.sd_setImageWithURL(business.ratingImageURL!)
            guard let reviewNumber = business.reviewCount else {
                reviewLabel.text = "No review"
                return
            }
            reviewLabel.text = "\(reviewNumber) review(s)"
            addressLabel.text = business?.address
            categoriesLabel.text = business?.categories
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
