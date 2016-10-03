//
//  FiltersSeeAllTableViewCell.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

@objc protocol FiltersSeeAllDelegate {
    optional func filtersSeeAllDelegate(filtersSeeAllTableViewCell: FiltersSeeAllTableViewCell, didSet title:String)
}
class FiltersSeeAllTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    var delegate: FiltersSeeAllDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        delegate?.filtersSeeAllDelegate?(self, didSet: titleLabel.text!)
    }

}
