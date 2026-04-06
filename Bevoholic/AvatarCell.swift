//
//  AvatarCell.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 4/5/26.
//

import UIKit

class AvatarCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.cornerRadius = imageView.frame.width / 2
        layer.borderWidth = 0
    }

    func configure(with imageName: String, selected: Bool) {
        imageView.image = UIImage(named: imageName)
        layer.borderWidth = selected ? 3 : 0
        layer.borderColor = selected ? UIColor.white.cgColor : nil
        layer.cornerRadius = imageView.frame.width / 2
    }
}
