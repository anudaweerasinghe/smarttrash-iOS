//
//  RedeemScreen.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 1/4/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import UIKit
import EZLoadingActivity

import AVFoundation

import CoreLocation

import Alamofire


class RedeemQRScreen: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CLLocationManagerDelegate {
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    var locationManager: CLLocationManager!
    var latitude: Double!
    var longitude: Double!
    var authCode: String!
    
    let defaultValues = UserDefaults.standard
    var phone: String!
    
    var qrString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        qrString = ""
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            errorMessage(message: "Sorry, We encountered an error while getting your camera data.")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            errorMessage(message: "Sorry, we encountered an error while initializing the QR Code scanner")
            return
        }
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        captureSession.startRunning()
        
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        qrString = nil
        captureSession = AVCaptureSession()
        return
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            errorMessage(message: "No QR Code detected for scanning. Please try again")
            return
        }
        
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            captureSession.stopRunning()
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                EZLoadingActivity.show("Verifying", disableUI: true)

                qrString = metadataObj.stringValue
                
                determineMyCurrentLocation()
                phone = defaultValues.string(forKey: "mobile")
                
                
                
            }else{
                errorMessage(message: "You have not scanned a QR code from an authorized bin")
            }
        }
        captureSession.stopRunning()
    }
    
    func verifyQR(){
        let utf8QrString = qrString?.data(using: String.Encoding.utf8)
        
        authCode = (utf8QrString?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
        
        let parameters: Parameters = [
            "authCode": authCode,
            "phone": phone,
            "redeemLat": latitude,
            "redeemLng": longitude
        ]
        
        let URL: String = "http://128.199.178.5:8080/garbageback/redeem/code-verify"
        
        Alamofire.request(URL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{(response)->Void in
            response.result.ifSuccess {
                
                if(response.response?.statusCode==200){
                    EZLoadingActivity.hide(true, animated: true)
                    let redeemPicController = self.storyboard?.instantiateViewController(withIdentifier: "RedeemPicScreen")as! RedeemPicScreen
                    redeemPicController.location = response.result.value!
                    redeemPicController.lat = self.latitude
                    redeemPicController.lng = self.longitude
                    redeemPicController.phone = self.phone
                    redeemPicController.qrCode = self.authCode
                    redeemPicController.hidesBottomBarWhenPushed=true
                    self.navigationController?.pushViewController(redeemPicController, animated: true)

                }else{
                    EZLoadingActivity.hide(false, animated: true)

                    self.errorMessage(message: response.result.value!)
                    
                }
            }
            response.result.ifFailure {
                EZLoadingActivity.hide(false, animated: true)

                self.errorMessage(message: response.result.value!)
                
            }
        }
    }
    
    
    func errorMessage(message:String){
        
        let alertController = UIAlertController(title: "Redemption Failure", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default,
                                     handler: { _ in
                                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                                        let dashboardController = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
                                        dashboardController?.hidesBottomBarWhenPushed=true
                                        self.navigationController?.pushViewController(dashboardController!, animated: true)})
    
        alertController.addAction(OKAction)
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true,
                         completion:nil)
        }
        
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
                                         handler:{ _ in if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
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
        
        latitude=userLocation.coordinate.latitude
        longitude=userLocation.coordinate.longitude
        if(qrString == nil){
            return
        }else{
            verifyQR()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error \(error)")
    }
    
}

