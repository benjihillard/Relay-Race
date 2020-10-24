//
//  ViewController.swift
//  Relay Race
//
//  Created by Benjamin Hillard on 10/23/20.
//  Copyright © 2020 Benjamin Hillard. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var radiusIndicator: UILabel!
    @IBOutlet weak var radiusStepper: UIStepper!
    @IBOutlet weak var maxDistanceIndicator: UILabel!
    @IBOutlet weak var checkPointStepper: UIStepper!
    @IBOutlet weak var checkPointIndicator: UILabel!
    
    let locationManager = CLLocationManager()
    
    var regionInMeters: Double = 1609.34
    let milesTometers = 1609.34
    var checkPoints = 1
    var checkPointSize = 30.0
    
    let geoCoder = CLGeocoder()
    var directionsArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationServices()
        radiusIndicator.text = "Circuit Radius is: 1 mile"
        maxDistanceIndicator.text = "Max Distance is: " + String(floor(2.0 * .pi)) + " miles"
        checkPointIndicator.text = "Check Points: 1"
        radiusStepper.maximumValue = 5.0
        radiusStepper.minimumValue = 1.0
        radiusStepper.stepValue = 1.0
        radiusStepper.value = 1.0
        checkPointStepper.maximumValue = 6.0
        checkPointStepper.minimumValue = 1.0
        checkPointStepper.stepValue = 1.0
        checkPointStepper.value = 1.0
        
    }
    
    @IBAction func updateRadius(_ sender: UIStepper) {
        regionInMeters = milesTometers * sender.value
        checkPointSize = checkPointSize * sender.value
        radiusIndicator.text = "Circuit Radius is: " + String(Int(sender.value)) + "miles"
        maxDistanceIndicator.text = "Max Distance is: " + String(floor(2.0 * .pi * sender.value)) + " miles"
        centerViewOnUserLocation()
    }
    
    @IBAction func updateCheckPoints(_ sender: UIStepper) {
        checkPoints = Int(sender.value)
        checkPointIndicator.text = "Check Points: " + String(Int(sender.value))
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    

    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    
    func getRandomCoor() -> CLLocationCoordinate2D {
        if let location = locationManager.location?.coordinate {
            var latsign = 0.0
            var lonsign = 0.0
            let range = regionInMeters / 111111
            if (location.latitude < 0){
                latsign = -1.0
            }else{
                latsign = 1.0
            }
            if (location.longitude < 0){
                lonsign = -1.0
            }else{
                lonsign = 1.0
            }
            let lat = (latsign * (Double.random(in: (abs(location.latitude) - range/2)..<(abs(location.latitude) + range/2))))
            let lon = (lonsign * (Double.random(in: (abs(location.longitude) - range/2)..<(abs(location.longitude) + range/2))))
            return CLLocationCoordinate2DMake(lat, lon)
        }
        return CLLocationCoordinate2D();
    }

    
    
    /*func getDirections(dest: CLLocationCoordinate2D)  {
        
        let request = createDirectionsRequest(from: dest)
        let directions = MKDirections(request: request)
        //resetMapView(withNew: directions)
        return directions
        directions.calculate { [unowned self] (response, error) in
            //TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show response not available in an alert
            for route in response.routes {
                print(route.polyline)
                self.mapView.addOverlay(route.polyline)
                //self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }*/
    
    
    func createDirectionsRequest(start: CLLocationCoordinate2D, dest: CLLocationCoordinate2D) -> MKDirections {
        let destinationCoordinate       = dest
        let startingLocation            = MKPlacemark(coordinate: start)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .walking
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        //resetMapView(withNew: directions)
        return directions
    }
    
    func resetMapView() {
        mapView.removeOverlays(mapView.overlays)
        
    }
    
    func getCurcuit(){
        resetMapView()
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return}
        
        var circuit: [MKDirections] = []
        var randPoint = getRandomCoor()
        self.mapView.addOverlay(MKCircle(center: randPoint,radius: checkPointSize))
        circuit.append(createDirectionsRequest(start: location, dest: randPoint))
        
        if(checkPoints > 1){
            for n in 2...checkPoints {
                let nextPoint = getRandomCoor()
                circuit.append(createDirectionsRequest(start: randPoint, dest: nextPoint))
                randPoint = nextPoint
                self.mapView.addOverlay(MKCircle(center: randPoint,radius: checkPointSize))
            }
        }
        
        for directions in circuit{
            directions.calculate { [unowned self] (response, error) in
                //TODO: Handle error if needed
                guard let response = response else { return } //TODO: Show response not available in an alert
                for route in response.routes {
                    
                    self.mapView.addOverlay(route.polyline)
                    
                    
                    //self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            }
        }
    }
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        
        getCurcuit()
    }
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    
}

extension ViewController: MKMapViewDelegate {
    
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
}

