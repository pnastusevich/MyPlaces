//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 18.04.24.
//

import RealmSwift

let realm = try! Realm() // этот экземпляр точка входа в базу данных

class StorageManager {
    
    static func saveObject(_ place: Place) {
        
        try! realm.write ({ // запись в базу
            realm.add(place)
        })
    }
    
    static func deleteObject(_ place: Place) {
        
        try! realm.write {
            realm.delete(place)
        }
    }
}
