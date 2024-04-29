//
//  MapManager.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 28.04.24.
//

import UIKit
import MapKit

class MapManager {
    let locationManager = CLLocationManager()
    
    private let regionInMeters = 1000.00
    private var directionsArray:  [MKDirections] = [] // массив маршрутов
    private var placeCoordinate: CLLocationCoordinate2D?
    
    func setupPlaceMark(place: Place, mapView: MKMapView) {
        
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
            annotation.title = place.name
            annotation.subtitle = place.type
            
            guard let placemarkLocation = placemark?.location else { return } // определяем местоположение маркера
            
            annotation.coordinate = placemarkLocation.coordinate // привязываем координаты маркера к объекту
            self.placeCoordinate = placemarkLocation.coordinate // передаём координаты для построения маршрута
            
            mapView.showAnnotations([annotation], animated: true) // создаём анатацию к объекту
            mapView.selectAnnotation(annotation, animated: true) // вызываем его
            
        }
    }
    
        // проверка доступности сервисов шеолокации
    func checkLocationServices(mapView: MKMapView, segueIdentifier: String, closure: () ->()) {
        if CLLocationManager.locationServicesEnabled() { // если служюа геолокации досутпна то вызываем проверку локации
            
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            checkLocationAuthorization(mapView: mapView, segueIdentifier: segueIdentifier)
            closure()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlert(
                    title: "Location Services are Disabled",
                    message: "To enable it go: Settings → Privacy → Location Services and turn On"
                )
            }
        }
    }
    
        // Проверка авторизации приложения для использования сервисов геолокации
    func checkLocationAuthorization(mapView: MKMapView, segueIdentifier: String) {
        
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if segueIdentifier == "getAddress" { showUserLocation(mapView: mapView) }
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
    
    // фокус карты на местположении юзера
    func showUserLocation(mapView: MKMapView) {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Строим маршрут от местоположения пользователя до заведения
    func getDirections(for mapView: MKMapView, previousLocation: (CLLocation) -> ()) { // определяем кординаты пользователя
        
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        
        locationManager.startUpdatingLocation() // режим постоянного отслеживания пользователя
        previousLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) // передаём текущие координаты пользователя
        
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        
        let directions = MKDirections(request: request) // создаём маршрут request запрос на построение маршрута
        
        resetMapView(withNew: directions, mapView: mapView) // удаляем старые маршруты
        
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
                
                mapView.addOverlay(route.polyline) // polyline хранит подробную геометрию всего маршрута
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true) // фокусируем карту, чтобы выл виден весь маршрут
                
                let distans = String(format: "%,1f", route.distance / 1000) // "%,1f" округление до десятых
                let timeInterval = route.expectedTravelTime // время на путь в секундах
                
                print("Растояние до места: \(distans) км.") // для отображения в приложении нужно создать лайбл и скрыть его при запуске и отображать его только после построения маршрута, передавв него эти значения
                print("Время в пути составит: \(timeInterval) сек.")
            }
        }
    }
    
    // Настройка запроса для расчета маршрута
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? { // настройка запроса для построения маршрута
        
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
    
    // Меняем отображаемую зону области карты в соответствии с перемещением пользователя
    func startTrackingUserLocation(for mapView: MKMapView, and location: CLLocation?, closure: (_ currentLocation: CLLocation) -> ()) {
        
        guard let location = location else { return }
        
        let center = getCenterLocation(for: mapView)
        
        guard center.distance(from: location) > 50 else { return } // если растояние от текущей до начальной точки > 50 метров, то передаём новые координаты в местоположение юзера равные текущему центру
        
        closure(center)
        }
    
    
    // Сброс всех ранее построенных маршрутов перед построением нового
    func resetMapView(withNew directions: MKDirections, mapView: MKMapView) {
        
        mapView.removeOverlays(mapView.overlays) // постовляем все текущие отображения маршрута
        directionsArray.append(directions) // directions массив маршрутов из параметра overlays
        
        let _ = directionsArray.map { $0.cancel() } // у каждого элемента массива вызываем метод cancel (тем самым закрывая)
        directionsArray.removeAll() 
    }
    
    
    // Определение центра отображаемой области карты
    func getCenterLocation(for mapView: MKMapView) -> CLLocation { // метод для определения координат в центре области
        
        let latitude = mapView.centerCoordinate.latitude // широта
        let longitude = mapView.centerCoordinate.longitude // долгота
        
        return CLLocation(latitude: latitude, longitude: longitude) // возвращаем широту и долготу координат в центре экрана
    }
    
    
    private func showAlert (title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = UIWindow.Level.alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true)
    }
    
    
}
