//
//  LoginScreen.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 6/17/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import UIKit

import Alamofire
import EZLoadingActivity


class LoginScreen: UIViewController {
    
    let defaultValues = UserDefaults.standard
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var mobileText: UITextField!
    
    @IBAction func loginBtnOnClick(_ sender: UIButton) {
        
        verify()
        
    }
    
    override func viewDidLoad() {
        
        
        if defaultValues.string(forKey: "name") != nil{
            nameText.text=defaultValues.string(forKey: "name")
            mobileText.text = defaultValues.string(forKey: "mobile")
            
            verify()
            
        }else{
        }
        
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func emptyText(){
        let alertController = UIAlertController(title: "Textfield is Empty", message: "The Mobile and Name textfields cannot be empty. Please correctly enter your mobile number and name into the relevant textfield and try again", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default,
                                     handler: nil)
        alertController.addAction(OKAction)
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true,
                         completion:nil)
        }
    }
    
    func verify(){

        
        EZLoadingActivity.show("Verifying...", disableUI: true)

        
        let name: String = nameText.text!
        let mobile: String = mobileText.text!
        
        if(name==""){
            emptyText()
        }else if (mobile==""){
            
            emptyText()
            
        }else{
            let parameters: Parameters = [
                "name": name,
                "phone": mobile
            ]
            
            let URL: String = "http://128.199.178.5:8080/garbageback/garbageapi/new-user"
            
            Alamofire.request(URL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{(response)->Void in
                
                let statusCode = response.response?.statusCode
                
                if(statusCode==200){
                    EZLoadingActivity.hide(true, animated: true)

                    self.defaultValues.set(name,forKey:"name")
                    self.defaultValues.set(mobile,forKey:"mobile")
                    
                    
                    let dashboardController = self.storyboard?.instantiateViewController(withIdentifier: "tabController")
                    self.show(dashboardController!, sender: true)
                    
                }else{
                    EZLoadingActivity.hide(false, animated: true)

                    let alertController = UIAlertController(title: "Login Failed", message: "We encountered a problem when verifying your credentials. Please check your name and mobile number before trying again", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default,
                                                 handler: nil)
                    alertController.addAction(OKAction)
                    OperationQueue.main.addOperation {
                        self.present(alertController, animated: true,
                                     completion:nil)
                    }
                    
                }
                
            }
        }
        
        
    }
}
