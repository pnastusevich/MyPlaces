//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 13.04.24.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!
    
    var places: Results<Place>! // автообновляемый тип контейнера, который возращает объекты по запросу. Аналог массива
    var ascedingSorting = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self) // self пишем потому что подразумеваем что подставляем ТИП данных place. Вызываем 
    }
    
    
    

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int { // возвращает количество секций. изначально 1
//        return 0
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // возр. колич ячеек
        return places.isEmpty ? 0 : places.count // если объект не пустой, то возращаем каунт контейнера
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // конфиг. ячейки
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        let place = places[indexPath.row]
        
        cell.nameLabel?.text = place.name // обращ. к объкту из массива places и далее к его св-ву
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        
        cell.imageOfPlace?.layer.cornerRadius = cell.imageOfPlace.frame.size.height / 2 // делаем изображение круглым
        cell.imageOfPlace?.clipsToBounds = true
            
        return cell
    }
    
    //MARK: Table view delegate
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? { // метод настравивает пользоваельские действия свайпом с права на лево
//        
//        let place = places[indexPath.row]
//        
//        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in
//            StorageManager.deleteObject(place)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//        }
//        
//        return UISwipeActionsConfiguration(actions: [deleteAction])
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { // аналог метода выше, только предназначен для мегьшего количства действий
        
        if editingStyle == .delete {
            let place = places[indexPath.row]
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
    }

    
     // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = tableView.indexPathForSelectedRow else { return } // indexPathForSelectedRow - индекс строки по которой идёт тап
            let place = places[indexPath.row]
            
            let newPlaceViewController = segue.destination as! NewPlaceViewController
            newPlaceViewController.currentPlace = place // передали объект из выбранной ячейки на экран NewPlaceVC   
        }
    }
    
    
    @IBAction func unwindSegue (_ segue: UIStoryboardSegue) {
        guard let newPlaceViewControler = segue.source as? NewPlaceViewController else { return }
        
        newPlaceViewControler.savePlace()
        tableView.reloadData()
    }
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        
       sorting()
    }
    
    @IBAction func revesedSorting(_ sender: Any) {
        ascedingSorting.toggle() // меняет значение на противоположное
        
        if ascedingSorting { // если ascedingSorting == true, то меняем имдж
            reversedSortingButton.image = UIImage(imageLiteralResourceName: "ZA")
        } else {
            reversedSortingButton.image = UIImage(imageLiteralResourceName: "AZ")
        }
        
        sorting()
    }
    
    private func sorting() {
        
        if segmentedControl.selectedSegmentIndex == 0 { // если выбран правый, то сортируем по дате, если же левый то по имени
            places = places.sorted(byKeyPath: "date", ascending: ascedingSorting)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascedingSorting)
        }
        
        tableView.reloadData()
    }

}
