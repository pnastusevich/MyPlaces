//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 14.04.24.
//

import RealmSwift

class Place: Object { // Модель данных для хранения мест
    
    @objc dynamic var name: String = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    
    convenience init(name: String, location: String?, type: String?, imageData: Data?) { // convenience означает, что это назначеный инициалитатор, нужен чтобы инициализировать всех свойства
        self.init() // инициилизирует все св-ва по умолчанию
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
    }

}
