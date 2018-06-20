//
//  DisposeScreen.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 1/4/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import AlamofireObjectMapper

import GoogleMaps
import CoreLocation

class DisposeScreen: UIViewController, CLLocationManagerDelegate  {
    
    @IBOutlet weak var nearestBinLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager: CLLocationManager!
    
    var latitude: Double!
    var longitude: Double!
    
    var nlat: Double!
    var nlng: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        determineMyCurrentLocation()
        
        nearestBinLabel.numberOfLines=0
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupMap(){
        
        do {
            if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15)
        
        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let marker = GMSMarker(position: position)
        let markerImage = UIImage(named:"marker")!.withRenderingMode(.alwaysTemplate)
        let markerView = UIImageView(image: markerImage)
        
        marker.iconView = markerView
        marker.title = "Current Location"
        marker.map = mapView
        
        
        mapView.animate(to:camera)
        
        
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if(CLLocationManager.locationServicesEnabled()){
            
            
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                locationManager.startUpdatingLocation()
            }else if CLLocationManager.authorizationStatus() == .notDetermined{
                locationManager.requestWhenInUseAuthorization()
            }else if CLLocationManager.authorizationStatus() == .denied{
                let alertController = UIAlertController(title: "Location Access Denied", message: "We canot serve you as intended without access to your location. Please give location access to this app.", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default,
                                             
                                             handler: { _ in if let url = URL(string: UIApplicationOpenSettingsURLString) {
                                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                }})
                alertController.addAction(OKAction)
                OperationQueue.main.addOperation {
                    
                    
                    self.present(alertController, animated: true,
                                 completion:nil)
                }
            }
            
            
        }else{
            let alertController = UIAlertController(title: "Location Services Disabled", message: "We canot serve you as intended without access to your location. Please turn on location services.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default,
                                         
                                         handler: { _ in if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                            }})
            
            
            alertController.addAction(OKAction)
            OperationQueue.main.addOperation {
                self.present(alertController, animated: true,
                             completion:nil)
            }
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        
        // manager.stopUpdatingLocation()
        
        latitude=userLocation.coordinate.latitude
        longitude=userLocation.coordinate.longitude
        
        setupMap()
        getNearestBinInfo()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    
    
    func getNearestBinInfo(){
        let parameters: Parameters = [
            "currentLocationLat": latitude,
            "currentLocationLng": longitude
        ]
        
        let URL: String = "http://128.199.178.5:8080/garbageback/garbageapi/nearest-bin"
        
        Alamofire.request(URL,method:.post,parameters:parameters,encoding:JSONEncoding.default).responseObject{ (response: DataResponse<NearestBin>) in
            
            let nearestResponse = response.result.value
            
            let distance: Double = (nearestResponse?.distance)!/1000
            
            let distString: String = String(format: "%.1f", distance)
            
            if let nearestbin = nearestResponse?.bin{
                let name: String = nearestbin.name!
                let info: String = nearestbin.info!
                self.nlat = nearestbin.lat!
                self.nlng = nearestbin.lng!
                
                let binPosition = CLLocationCoordinate2D(latitude: self.nlat, longitude: self.nlng)
                
                let binMarker = GMSMarker(position: binPosition)
                
                binMarker.icon = UIImage(named: "bin-mk")
                binMarker.title = "Dialog @"+name
                binMarker.snippet=info
                binMarker.map = self.mapView
                
                self.nearestBinLabel.text = "\nThe Nearest Bin is at " + name + ", " + distString + "km away from current location"
                
                
            }
            
        }
    }
    
    @IBAction func navigateOnClick(_ sender: Any) {
        
        
        
        let nlatString: String = String(format: "%.20f", nlat)
        let nlngString: String = String(format: "%.20f", nlng)
        
        
        
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination="+nlatString+","+nlngString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        
    }
    
}
