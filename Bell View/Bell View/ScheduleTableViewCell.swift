//
//  ScheduleTableViewCell.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/21/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit

class ScheduleTableViewCell: UITableViewCell {
    
    //MARK: - Local vars
    private var _cellHighlighted:Bool?
    
    //MARK: - Property determination
    var cellHighlighted:Bool? {
        set (newValue) {
            _cellHighlighted = newValue
        }
        
        get {
            return _cellHighlighted
        }
    }
    
    //MARK:  - Properties
    @IBOutlet weak var scheduleLabel: UILabel!
    
    //MARK: - Event handlers
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
