//
//  RedeemPicScreen.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 6/18/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import UIKit
import EZLoadingActivity

import Alamofire
import ObjectMapper
import AlamofireObjectMapper

class RedeemPicScreen: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var imagePickerController : UIImagePickerController!
    
    var location:String = ""
    
    var lat: Double!
    var lng: Double!
    var phone: String!
    var qrCode: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        EZLoadingActivity.show("Verifying...", disableUI: true)
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        let uuid = UUID().uuidString
        saveImage(imageName: uuid)
        
    }
    
    func saveImage(imageName: String){

        
        let fileManager = FileManager.default
        let imagePath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
        let image = imageView.image!
        let data = UIImagePNGRepresentation(image)
        fileManager.createFile(atPath: imagePath as String, contents: data, attributes: nil)
        
        uploadImg(imgPath: imagePath)
    }
    
    func uploadImg(imgPath: String){
        
        
        let image = UIImage(contentsOfFile: imgPath)
        let imgData = UIImageJPEGRepresentation(image!, 0.2)!


        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imgData, withName: "file",fileName: "file", mimeType: "image/jpg")
        },
                         to:"http://128.199.178.5:8080/garbageback/redeem/upload/?location="+location)
        { (result) in
            switch result {
            case .success(let upload, _, _):


                upload.responseString { response in
                    if(response.response?.statusCode == 200){
                        let imgDir:String = response.result.value!
                        let imgDir2: String = imgDir.replacingOccurrences(of: "\"", with: "")
                        let img:String = imgDir2.replacingOccurrences(of: "/var/www/html/", with: "http://128.199.178.5/")
                        let parameters: Parameters = [
                            "image": img,
                            "lat": self.lat,
                            "lng": self.lng,
                            "phone": self.phone,
                            "qrCode": self.qrCode
                        ]

                        Alamofire.request("http://128.199.178.5:8080/garbageback/redeem/pic-verify", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{(response)->Void in
                            response.result.ifSuccess {
                                if(response.response?.statusCode==200){
                                    EZLoadingActivity.hide(true,animated: true)
                                    self.imagePickerController.dismiss(animated: true, completion: nil)
                                    let alertController = UIAlertController(title: "Successful Redemption", message: "The verification was successful. You will receive a SMS message confirming your reward", preferredStyle: .alert)
                                    let OKAction = UIAlertAction(title: "OK", style: .default,
                                                                 handler: { _ in
                                                                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                                                                    let dashboardController = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
                                                                    self.navigationController?.pushViewController(dashboardController!, animated: true)
                                    })

                                    alertController.addAction(OKAction)
                                    OperationQueue.main.addOperation {
                                        self.present(alertController, animated: true,
                                                     completion:nil)
                                    }

                                }else{
                                    EZLoadingActivity.hide(false, animated: true)
                                    self.imagePickerController.dismiss(animated: true, completion: nil)
                                    self.message(message: response.result.value!, title: "Verification Failed")
                                }

                            }
                            response.result.ifFailure {
                                EZLoadingActivity.hide(false, animated: true)
                                self.imagePickerController.dismiss(animated: true, completion: nil)
                                self.message(message: "Unfortunately, we encountered an error while verifying your disposal. Please try again later.", title: "Verification Failed")
                            }

                        }

                    }else{
                        EZLoadingActivity.hide(false,animated: true)
                        self.imagePickerController.dismiss(animated: true, completion: nil)
                        self.message(message: "We encountered an error while uploading your picture. Please try again later", title: "Upload Failed")
                    }


                }

            case .failure(let encodingError):
                EZLoadingActivity.hide(false,animated: true)
                self.imagePickerController.dismiss(animated: true, completion: nil)
                self.message(message: "We encountered an error while uploading your picture. Please try again later", title: "Upload Failed")
            }
        }
    }
    
    func message(message:String, title: String){
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default,
                                     handler: { _ in
                                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                                        let dashboardController = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
                                        self.navigationController?.pushViewController(dashboardController!, animated: true)
        })
        alertController.addAction(OKAction)
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true,
                         completion:nil)
        }
        
    }
    
    
    
}
