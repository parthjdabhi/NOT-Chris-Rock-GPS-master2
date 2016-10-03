//
//  FiltersDropdownTableViewCell.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

@objc protocol FiltersDropdownDelegate {
    optional func filtersDropdownDelegate(filtersDropdownTableViewCell: FiltersDropdownTableViewCell, didSet dropdownImg: UIImage)
}
class FiltersDropdownTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dropdownImage: UIImageView!
    
    var delegate: FiltersDropdownDelegate?
//    var FiltersDropdown
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        delegate?.filtersDropdownDelegate?(self, didSet: dropdownImage.image!)
    }
}
