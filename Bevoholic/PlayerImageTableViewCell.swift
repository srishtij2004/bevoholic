//
//  PlayerImageTableViewCell.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 4/7/26.
//

import UIKit

class PlayerImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var playerImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        playerImageView.contentMode = .scaleAspectFit
        playerImageView.clipsToBounds = true
        
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    
}
