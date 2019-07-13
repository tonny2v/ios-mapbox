//
//  FirstViewController.swift
//  cocoa-test
//
//  Created by Jiangshan on 12/31/18.
//  Copyright © 2018 Jiangshan. All rights reserved.
//

import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class FirstViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    var mapView: NavigationMapView!
    var navigateButton: UIButton!
    var lonlatLabel: UILabel!
    
    var directionsRoute: Route?
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
//        let styleURL = URL(string: "mapbox://styles/mapbox/streets-zh-v1")
        let styleURL = URL(string: "mapbox://styles/mapbox/light-v9")
        
        mapView = NavigationMapView(frame: view.bounds, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.delegate = self
        mapView.showsUserLocation = true;
        mapView.setCenter(CLLocationCoordinate2D(latitude: 22.5632,
                                                 longitude: 113.9774),
                          zoomLevel: 12, animated: true)
        mapView.setUserTrackingMode(.follow, animated: true)
        view.addSubview(mapView)
        // Do any additional setup after loading the view, typically from a nib.
        addLabel()
        addButton()
    }
    
    func addLabel(){
        lonlatLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 200, height: 50))
        view.addSubview(lonlatLabel)
    }
    
    func addButton(){
        navigateButton = UIButton(frame: CGRect(x: (view.frame.width/2) - 100, y: view.frame.height - 160, width: 200, height: 50))
        navigateButton.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigateButton.setTitle("Navigate", for: .normal)
        navigateButton.setTitleColor(UIColor(red: 59/255, green: 178/255, blue:208/255, alpha: 1), for: .normal)
        navigateButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        navigateButton.layer.cornerRadius = 25
        navigateButton.layer.shadowOffset = CGSize(width: 0, height: 0)
        navigateButton.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        navigateButton.layer.shadowOpacity = 0.3
        navigateButton.addTarget(self, action: #selector(navigateButtonWasPressed(_:)), for: .touchUpInside)
        view.addSubview(navigateButton)
    }
    
    @objc func navigateButtonWasPressed(_ sender: UIButton){
        mapView.setUserTrackingMode(.none, animated: true)
        let location = CLLocationCoordinate2D(latitude: 22.59, longitude: 113.93)
        
        let annotation = MGLPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Start Navigation"
        mapView.addAnnotation(annotation)
        
        calculateRoute(from: mapView.userLocation!.coordinate, to: location, completion: {(route, error) in
            if error != nil {
                print("Error getting route")
            }
        })
    }
    
    func calculateRoute(from originCoord: CLLocationCoordinate2D, to destinationCoord: CLLocationCoordinate2D, completion: @escaping (Route?, Error?) -> Void){
        let origin = Waypoint(coordinate: originCoord, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destinationCoord, coordinateAccuracy: -1, name: "End")
        
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        _ = Directions.shared.calculate(options, completionHandler: {(waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // draw the line
            self.drawRoute(route: self.directionsRoute!)
            let coordinateBounds = MGLCoordinateBounds(sw: destinationCoord, ne: originCoord)
            let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            let routeCam = self.mapView.cameraThatFitsCoordinateBounds(coordinateBounds, edgePadding: insets) 
            self.mapView.setCamera(routeCam, animated: true)
        })
    }
    
    func drawRoute(route: Route){
        guard route.coordinateCount > 0 else { return }
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource{
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.231372549, green: 0.6980392157, blue: 0.8156862745, alpha: 1))
            lineStyle.lineOpacity = NSExpression(forConstantValue: 0.8)
            lineStyle.lineWidth = NSExpression(forConstantValue: 4.0)
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
            
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool{
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation){
        let navigationVC = NavigationViewController(for: directionsRoute!)
        present(navigationVC, animated: true, completion: nil)
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            lonlatLabel.text = String(format: "%f, %f", location.coordinate.longitude, location.coordinate.latitude)
            print(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied){
            showLocationDisabledPopUp()
        }
    }
    
    func showLocationDisabledPopUp(){
        let alertController = UIAlertController(title: "Backgroud Location Access Disabled", message: "I Just Need Your Location", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let openAction = UIAlertAction(title: "Open Settings", style: .default){(action) in
            if let url = URL(string: UIApplication.openSettingsURLString){
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
