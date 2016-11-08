//
//  ReviewTableCell.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 10/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class ReviewTableCell: UITableViewCell {
  var review: Review!
  
  @IBOutlet weak var profilePicView: UIImageView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var excerptLabel: UILabel!
  
  func initializeCell(review: Review) {
    
    profilePicView.setBorder(1, color: clrGreen)
    profilePicView.setCornerRadious(profilePicView.frame.width/2)
    
    self.review = review
    profilePicView.sd_setImageWithURL(review.userImageURL!)
    usernameLabel.text = review.username!
    excerptLabel.text = review.excerpt!
  }
}
