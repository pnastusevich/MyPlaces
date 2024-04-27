//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 13.04.24.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let searchController = UISearchController(searchResultsController: nil) // с помощью nil говорим что хотим использовать тот же вью для отображение, где и находиться поиск
    
    private var places: Results<Place>! // автообновляемый тип контейнера, который возращает объекты по запросу. Аналог массива
    private var filtredPlaces: Results<Place>! // колекция для фильтрации при работе с поиковиком (сюда будут помещаться значения)
    private var ascedingSorting = true
    private var searchBarIsEmpty: Bool { // если в поисковике есть текс, то возвращает true, если нет, то false
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool { // возвращает true кгода поисковая строка активирована
        return searchController.isActive && !searchBarIsEmpty
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        places = realm.objects(Place.self) // self пишем потому что подразумеваем что подставляем ТИП данных place. Вызываем 
        
            // настройка searchController
        searchController.searchResultsUpdater = self // говорим что получаетелем инфы об изменении текста в поисковой строке должен быть сам класс
        searchController.obscuresBackgroundDuringPresentation = false // отключаем и теперь можем взаимодействовать с вью контроллером как основным (смотреть, изменять, удалять записи)
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController // поисковик будет ингегрирован в navigationBar
        definesPresentationContext = true // отпускаем строку поиска при переходе на другой экран
        
    }
    
    
    

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int { // возвращает количество секций. изначально 1
//        return 0
//    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // возр. колич ячеек
        if isFiltering {
            return filtredPlaces.count // если поисковая строка активна, то возращаем количество отсортированных элементов
        }
        return /*places.isEmpty ? 0 :*/ places.count // если объект не пустой, то возращаем каунт контейнера
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // конфиг. ячейки
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        let place = isFiltering ? filtredPlaces[indexPath.row] : places[indexPath.row] // если поисковая строка активна, то свойству place присваиваем язначения из осортирован
    
        cell.nameLabel?.text = place.name // обращ. к объкту из массива places и далее к его св-ву
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        cell.cosmosView.rating = place.rating
            
        return cell
    }
    
    //MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
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
            
            let place = isFiltering ? filtredPlaces[indexPath.row] : places[indexPath.row]
        
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

extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filtredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText) // выполняем поиск по полям name и location и фильтруем данные по значению из параметра searchText в не зависимости от регистра символов (а А)
        
        tableView.reloadData()
    }
}
