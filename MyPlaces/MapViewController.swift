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
    
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 10_000.00
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self // назначили сам класс делегатом протакола MKMapViewDelegate
        setupPlaceMark()
        checkLocationServices()
    }
    
    @IBAction func centerViewInUserLocation() {
        
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    @IBAction func closeViewController() {
        dismiss(animated: true)
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
    
    private func showAlert (title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
  
}

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
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}
