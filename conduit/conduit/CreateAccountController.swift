//
//  CreateAccountController.swift
//  conduit
//
//  Created by Sherman Leung on 3/7/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import Foundation
import UIKit

class CreateAccountController : UIViewController {
  @IBOutlet var usernameField: UITextField!
  @IBOutlet var passwordField: UITextField!
  @IBOutlet var retypePasswordField: UITextField!
  @IBOutlet var emailField: UITextField!
  @IBOutlet var phoneField: UITextField!
  @IBOutlet var licenseField: UITextField!
  
  @IBAction func cancel(sender: AnyObject) {
    navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func dismissKeyboard(sender: AnyObject) {
    view.endEditing(true)
  }
  
  @IBAction func createAccount(sender: AnyObject) {
    APIModel.post("/sessions", parameters: ["user_id": "1"]) { (result, error) -> () in
      if (error == nil) {
        var defaults = NSUserDefaults.standardUserDefaults()
        var sessionKey = result!["session"] as! String
        defaults.setValue("session", forKey: sessionKey)
      } else {
        NSLog("ERROR: Session error")
      }
    }
  }
}
