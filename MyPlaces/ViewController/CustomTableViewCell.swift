//
//  CustomTableViewCell.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 14.04.24.
//

import UIKit
import Cosmos

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var imageOfPlace: UIImageView! {
        didSet {
            imageOfPlace?.layer.cornerRadius = imageOfPlace.frame.size.height / 2 // делаем изображение круглым
            imageOfPlace?.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var cosmosView: CosmosView! {
        didSet {
            cosmosView.settings.updateOnTouch = false // отключает возожность менять рейтинг на мейн ВК
        }
    }
}
