//
//  EmojiCollectionViewCell.swift
//  Hippo
//
//  Created by Vishal on 22/04/18.
//  Copyright © 2018 CL-macmini-88. All rights reserved.
//

import UIKit

class EmojiCollectionViewCell: UICollectionViewCell {
    
    var attribute = FeedbackAttributes()

    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellImage.contentMode = .scaleAspectFit
        cellImage.image = UIImage()
    }
    
    func setData(data: FeedbackAttributes) {
        attribute = data
        cellImage.image = attribute.image
        cellLabel.text = attribute.title
        setupCell()
    }
    
    override var isSelected: Bool {
        didSet {
            setupCell()
        }
    }
    func setupCell() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.cellImage.alpha = self.isSelected ? 1.0 : 0.3
            self.cellLabel.alpha = self.isSelected ? 1.0 : 0.3
            self.cellLabel.font = self.isSelected ? UIFont.boldSystemFont(ofSize: 15) : UIFont.boldSystemFont(ofSize: 11)
            if self.isSelected {
                self.cellImage.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } else {
                self.cellImage.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
        }, completion: nil)
    }
}
