//
//  PlayerProfile.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 3/9/26.
//

import UIKit

class PlayerProfile: UIImageView {

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
    }

    private func setup() {
        clipsToBounds = true
        contentMode = .scaleAspectFill
        //default
        image = UIImage(named: "longhornHead")
        backgroundColor = UIColor(red: 250/255, green: 193/255, blue: 145/255, alpha: 1.0) 
    }
}
