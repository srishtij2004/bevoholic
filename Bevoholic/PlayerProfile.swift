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

        // default avatar
        image = UIImage(systemName: "person.circle.fill")
        tintColor = .systemOrange
    }
}
