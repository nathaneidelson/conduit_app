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
  @IBOutlet weak var firstNameField: UITextField!
  @IBOutlet weak var lastNameField: UITextField!
  @IBOutlet var passwordField: UITextField!
  @IBOutlet var retypePasswordField: UITextField!
  @IBOutlet weak var retypePasswordErrorLabel: UILabel!
  @IBOutlet var emailField: UITextField!
  @IBOutlet weak var emailErrorLabel: UILabel!
  @IBOutlet var licenseField: UITextField!
  @IBOutlet weak var scrollView: UIScrollView!
  
  var activeTextField : UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    highlightError(firstNameField)
    highlightError(lastNameField)
    highlightError(passwordField)
    highlightError(retypePasswordField)
    retypePasswordErrorLabel.text = ""
    retypePasswordErrorLabel.textColor = StyleColor.getColor(.Error, brightness: .Medium)
    highlightError(emailField)
    emailField.autocorrectionType = UITextAutocorrectionType.No
    emailErrorLabel.text = ""
    emailErrorLabel.textColor = StyleColor.getColor(.Error, brightness: .Medium)
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
//    self.registerForKeyboardNotifications()
  }
  
  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  
  /////////////////////// Begin Keyboard Scrolling Code ////////////////////////
  //
  // http://creativecoefficient.net/swift/keyboard-management/
  // https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
  //
  
  func registerForKeyboardNotifications() {
    let notificationCenter = NSNotificationCenter.defaultCenter()
    notificationCenter.addObserver(self, selector: "keyboardWillBeShown", name: UIKeyboardWillShowNotification, object: nil)
    notificationCenter.addObserver(self, selector: "keyboardWillBeHidden", name: UIKeyboardWillHideNotification, object: nil)
  }
  
  func keyboardWillBeShown(sender : NSNotification) {
    
    let info : NSDictionary = sender.userInfo!
    let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
    let keyboardSize: CGSize = value.CGRectValue().size
    let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
    scrollView.contentInset = contentInsets
    scrollView.scrollIndicatorInsets = contentInsets
    
    // if necessary, do scrolling
    var aRect: CGRect = self.view.frame
    aRect.size.height -= keyboardSize.height
    let activeTextFieldRect: CGRect? = activeTextField?.frame
    let activeTextFieldOrigin: CGPoint? = activeTextFieldRect?.origin
    if (!CGRectContainsPoint(aRect, activeTextFieldOrigin!)) {
      scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
    }
    
  }
  
  func keyboardWillBeHidden(sender: NSNotification) {
    let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
    scrollView.contentInset = contentInsets
    scrollView.scrollIndicatorInsets = contentInsets
  }
  
  @IBAction func textFieldDidBeginEditing(textField: UITextField!) {
    activeTextField = textField
    scrollView.scrollEnabled = true
  }
  
  @IBAction func textFieldDidEndEditing(textField: UITextField!) {
    activeTextField = nil
    scrollView.scrollEnabled = false
  }
  
  //
  /////////////////////// End Keyboard Scrolling Code //////////////////////////

  @IBAction func cancel(sender: AnyObject) {
    navigationController?.popViewControllerAnimated(true)
  }
  
  @IBAction func dismissKeyboard(sender: AnyObject) {
    view.endEditing(true)
  }
  
  // Create account
  @IBAction func createAccount(sender: AnyObject) {
    
    
    if (checkInputs() == false) {
      let alertController = UIAlertController(title: "", message:
        "Please fill in all required inputs.", preferredStyle: UIAlertControllerStyle.Alert)
      alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
      
      self.presentViewController(alertController, animated: true, completion: nil)
      return
    }
    println("before post")
    // note phone number is mocked in the backend
    var params = ["email_address": emailField.text, "password": passwordField.text, "first_name": firstNameField.text, "last_name": lastNameField.text, "phone_number": "123456789", "license_plate": licenseField.text, "manufacturer": "None"]
    APIModel.post("users/create", parameters: params) { (result, error) -> () in
      if (error == nil) {
        // notify user that car has been added to their account!
        var licensePlate = result!["license_plate"].string!
        let alertController = UIAlertController(title: "", message: "\(licensePlate) has been added to your list of cars.",
          preferredStyle: UIAlertControllerStyle.Alert)
        var cars = result!["cars"].arrayValue
        var car_strings:[String] = cars.map { $0["license_plate"].string!}
        println(car_strings)
        // car license plates will appear as an alert
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        // @Nathan: we need to redirect it back to the login screen after the create to invite segue
        self.performSegueWithIdentifier("create_to_invite_segue", sender: self)
      } else {
        // this is if the user creation fails
        println(error)
        let alertController = UIAlertController(title: "", message: "There was an error creating your account. Please try again.",
          preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
        return
      }
    }
  }
  
  // Checks that all req'd fields are filled in and valid. Returns false for 
  // invalid inputs.
  func checkInputs() -> Bool {
    // Required fields: first/last name, password, retype password, email
    
    var error = false
    
    if (emailField.text == "" || !isValidEmail(emailField.text) || !isAvailableEmail(emailField.text)) {
      error = true
    }
    
    if (firstNameField.text == "" || lastNameField.text == "" || passwordField.text == "" || retypePasswordField.text == "") {
      error = true
    }
    
    return !error
  }
  
  
  // Helper functions to highlight and unhighlight text boxes
  func highlightError(field : UITextField) {
    field.layer.cornerRadius = 5
    field.layer.borderWidth = 2
    field.layer.borderColor = StyleColor.getColor(.Error, brightness: .Medium).CGColor
    
  }
  
  func unhighlightError(field : UITextField) {
    field.layer.borderWidth = 0
    field.layer.borderColor = UIColor.clearColor().CGColor
  }

  @IBAction func checkRetypePasswordInput(sender: UITextField) {
    if (sender.text == "") {
      highlightError(sender)
      retypePasswordErrorLabel.text = ""
    } else if (passwordField.text != sender.text) {
      retypePasswordErrorLabel.text = "Passwords do not match."
      sender.text = ""
      highlightError(sender)
//      retypePasswordField.becomeFirstResponder()
    } else {
      unhighlightError(sender)
      retypePasswordErrorLabel.text = ""
    }
  }
  
  
  // Check the format of the email address
  @IBAction func checkEmailInput(sender: UITextField) {
    if (sender.text == "") {
      highlightError(sender)
      emailErrorLabel.text = ""
    } else if (isValidEmail(sender.text) == false) {
      highlightError(sender)
      emailErrorLabel.text = "Please enter a valid e-mail address."
    } else if (isAvailableEmail(sender.text) == false) {
      highlightError(sender)
      emailErrorLabel.text = "There is already an account with that e-mail."
    } else {
      unhighlightError(sender)
      emailErrorLabel.text = ""
    }
  }
  
  // https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
  func isValidEmail(s:String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(s)
    
  }
  
  func isAvailableEmail(s : String) -> Bool {
    // TODO(nisha): returns true if the email address is available, false if it's taken
    return true
  }
  
  // Check the input of a required field upon editing completion
  @IBAction func checkInput(sender: UITextField) {
    if (sender.text == "") {
      highlightError(sender)
    } else {
      unhighlightError(sender)
    }
  }


}
