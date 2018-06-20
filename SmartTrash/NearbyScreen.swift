//
//  NearbyScreen.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 1/4/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import UIKit

import GoogleMaps
import CoreLocation

import Alamofire
import ObjectMapper
import AlamofireObjectMapper

class NearbyScreen: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager: CLLocationManager!
    
    var latitude: Double!
    var longitude: Double!
    
    let defaultValues = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        determineMyCurrentLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 12)
        
        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let marker = GMSMarker(position: position)
        let markerImage = UIImage(named:"marker")!.withRenderingMode(.alwaysTemplate)
        let markerView = UIImageView(image: markerImage)
        
        marker.iconView = markerView
        marker.title = "Current Location"
        marker.map = mapView
        
        
        mapView.animate(to:camera)
        
        getBins()
        
        
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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
    func getBins(){
        
        let URL: String = "http://128.199.178.5:8080/garbageback/garbageapi/all-bins"
        
        Alamofire.request(URL).responseArray { (response: DataResponse<[Bin]>) in
            
            let binResponse = response.result.value
            
            if let binList = binResponse {
                for binDetails in binList{
                    
                    let binLat: Double = binDetails.lat!
                    let binLng: Double = binDetails.lng!
                    let binName: String = binDetails.name!
                    let binInfo: String = binDetails.info!
                    
                    let binPosition = CLLocationCoordinate2D(latitude: binLat, longitude: binLng)
                    
                    let binMarker = GMSMarker(position: binPosition)
                    
                    binMarker.icon = UIImage(named: "bin-mk")
                    binMarker.title = "Dialog @"+binName
                    binMarker.snippet=binInfo
                    binMarker.map = self.mapView
                    
                    
                    
                }
            }
            
        }
    }
    
    @IBAction func logOutBtnOnClick(_ sender: Any) {
        
        defaultValues.removeObject(forKey: "name")
        defaultValues.removeObject(forKey: "mobile")
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        let logOutController = self.storyboard?.instantiateViewController(withIdentifier: "LoginScreen")as! LoginScreen
        logOutController.hidesBottomBarWhenPushed=true
        self.navigationController?.pushViewController(logOutController, animated: true)
    }
    



}
