//
//  MapViewController.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 25.04.24.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 1000.00
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?
    var directionsArray:  [MKDirections] = [] // массив маршрутов
    var previousLocation: CLLocation? {
        didSet {
            startTrackingUserLocation()
        }
    }
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLabel.text = ""
        mapView.delegate = self // назначили сам класс делегатом протакола MKMapViewDelegate
        setupMapView()
        checkLocationServices()
    }
    
  
    // MARK: @IBAction METHODS
    
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress?(addressLabel.text) // передаём текущие значение адреса
        dismiss(animated: true)
    }
    
    @IBAction func centerViewInUserLocation() {
        showUserLocation()
    }
    
    @IBAction func closeViewController() {
        dismiss(animated: true)
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    // MARK: PRIVATE METHODS
    
    private func setupMapView() { // отображение кнопок на карте
        
        goButton.isHidden = true
        
        if incomeSegueIdentifier == "showPlace" {
            setupPlaceMark()
            mapPinImage.isHidden = true // скрываем mapPinImage
            addressLabel.isHidden = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    private func resetMapView(withNew directions: MKDirections) { // сбратываем старые машруты пере построением новых
        
        mapView.removeOverlays(mapView.overlays) // постовляем все текущие отображения маршрута
        directionsArray.append(directions) // directions массив маршрутов из параметра overlays
        
        let _ = directionsArray.map { $0.cancel() } // у каждого элемента массива вызываем метод cancel (тем самым закрывая)
        directionsArray.removeAll()
    }
    
    private func getDirections() { // определяем кординаты пользователя
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        
        locationManager.startUpdatingLocation() // режим постоянного отслеживания пользователя
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude) // передаём текущие координаты пользователя
        
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request) // создаём маршрут request запрос на построение маршрута
        resetMapView(withNew: directions) // удаляем старые маршруты
        
        directions.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.showAlert(title: "Error", message: "Directions is not available")
                return
            }
            
            for route in response.routes { // routes массив с маршрутами. каждый объект массива содержат сведения о геометрии для отображения на карте маршрута так же (время пути, дистанцию)
                
                self.mapView.addOverlay(route.polyline) // polyline хранит подробную геометрию всего маршрута
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // фокусируем карту, чтобы выл виден весь маршрут
                
                let distans = String(format: "%,1f", route.distance / 1000) // "%,1f" округление до десятых
                let timeInterval = route.expectedTravelTime // время на путь в секундах
                
                print("Растояние до места: \(distans) км.") // для отображения в приложении нужно создать лайбл и скрыть его при запуске и отображать его только после построения маршрута, передавв него эти значения
                print("Время в пути составит: \(timeInterval) сек.")
            }
        }
    }
    
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? { // настройка запроса для построения маршрута
        
        guard let destinationCoordinate = placeCoordinate else { return nil } //проверяем, можем ли определить место назначения
        let startingLocation = MKPlacemark(coordinate: coordinate) // стартовые координаты (координаты пользователя)
        let destination = MKPlacemark(coordinate: destinationCoordinate) // координаты точки назначения
        
        let request = MKDirections.Request() // свойство Request позволяет определить начальную и конечн. точку маршрута и планируемый вид транспорта
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true // позволяет пострить несколько маршрутов, если есть возможность
        
        return request
    }
    
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation { // метод для определения координат в центре области
        
        let latitude = mapView.centerCoordinate.latitude // широта
        let longitude = mapView.centerCoordinate.longitude // долгота
        
        return CLLocation(latitude: latitude, longitude: longitude) // возвращаем широту и долготу координат в центре экрана
    }
    
    private func setupPlaceMark() {
        
        guard let location = place.location else { return }
        
        let geocoder = CLGeocoder() // CLGeocoder отвечает за преобразование гео кардинат и названий. Класс помогает координаты широты и долготы преобразовать в вид для пользователя (название города, дома и т.д.)
        geocoder.geocodeAddressString(location) { (placemarks, error) in // позволяет определить гео по названию в виде строки. completionHandler возвращает массив из меток соответсвуюших адресу (1 или несколько, если ищем по названию)
                
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return } // извлекаем опционал из нового массива placemarks
            
            let placemark = placemarks.first // получили метку на карте
            
            let annotation = MKPointAnnotation() // объект изполучеться для описания точки на карте.
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            guard let placemarkLocation = placemark?.location else { return } // определяем местоположение маркера
            
            annotation.coordinate = placemarkLocation.coordinate // привязываем координаты маркера к объекту
            self.placeCoordinate = placemarkLocation.coordinate // передаём координаты для построения маршрута
            
            self.mapView.showAnnotations([annotation], animated: true) // создаём анатацию к объекту
            self.mapView.selectAnnotation(annotation, animated: true) // вызываем его
            
        }
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() { // если служюа геолокации досутпна то вызываем проверку локации
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location Services are Disabled",
                    message: "To enable it go: Settings → Privacy → Location Services and turn On"
                )
            }
        }
    }
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func checkLocationAuthorization() {
        
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse: 
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(title: "Your Location is not Availeble",
                               message: "To give permission Go to: Setting → MyPlaces → Location")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization() // запрашиваем разр. на использвоание геолокац
            break
        case .restricted:
            // show alert controller для использования служб геолокации
            break
        case .authorizedAlways: // когда прилож. разрешено исп. геолок постоянно
            break
        @unknown default:
            print("New case is available")
        }
    }
    
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func startTrackingUserLocation() {
        
        guard let previousLocation = previousLocation else { return }
        let center = getCenterLocation(for: mapView)
        
        guard center.distance(from: previousLocation) > 50 else { return } // если растояние от текущей до начальной точки > 50 метров, то
        self.previousLocation = center // передаём новые координаты в местоположение юзера равные текущему центру
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()

        }
    }
    
    private func showAlert (title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
  
}



// MARK: EXTENSION MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
         
        guard !(annotation is MKUserLocation) else { return nil } // если анотация это местоположение юзера, то нил
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKMarkerAnnotationView // переопределяем прошлую анотацию по идентификатору
        
        if annotationView == nil { //если на карте нет анотаций, то присваеваем ему новые значения
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        
        if let imageData = place.imageData {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView // отображаем на банере с правой стороны
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) { // отображаем адрес по координатам центра текущего региона (экрана)
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUserLocation()
            }
        }
        
        geocoder.cancelGeocode() // делаем отмету отложеного запроса geocoder
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in // преобразовываем координаты в адрес
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
                
            }
        }
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer { // настройки отображения маршрута на карте (цвет, ширина и тю.д.)
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}

// MARK: EXTENSION CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: PROTOCOL MapViewControllerDelegate

@objc protocol MapViewControllerDelegate {
    @objc optional func getAddress (_ address: String?)
    
    
}

