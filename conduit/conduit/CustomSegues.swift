//
//  CustomSegue.swift
//  conduit
//
//  Created by Nathan Eidelson on 4/14/15.
//  Copyright (c) 2015 Conduit. All rights reserved.
//

import Foundation

class SendToConversationSegue: UIStoryboardSegue {
  
  override func perform() {
    var sourceViewController: NewMessageViewController = self.sourceViewController as! NewMessageViewController
    var navigationController: UINavigationController = sourceViewController.navigationController!
    // Go back to the basics
    navigationController.popToRootViewControllerAnimated(false)
    
    // Switch to conversations view from root side menu
    var revealController: SWRevealViewController = navigationController.revealViewController()
    var newNavController : UINavigationController = revealController.rearViewController as! UINavigationController
    
    var rootViewController = newNavController.topViewController
    
    rootViewController.performSegueWithIdentifier("conversations_segue", sender: self)
    
    var conversationListNavigationController: UINavigationController = revealController.frontViewController as! UINavigationController
    var conversationListController: ConversationListViewController = conversationListNavigationController.visibleViewController as! ConversationListViewController
    // Create messages view
    
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var conversationViewController: ConversationViewController = ConversationViewController(layerClient: appDelegate.layerClient)
    
    
    var storyboard =  UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
    
    // initialize the license plate VC
    var licensePlateVC = storyboard.instantiateViewControllerWithIdentifier("NewRequest") as! LicenseInputController
    licensePlateVC.participantIdentifiers = sourceViewController.participantIdentifiers
//    licensePlateVC.licenseField.text = sourceViewController.licensePlateLabel.text
    
    // initialize the new message VC
    var newMessageViewController = storyboard.instantiateViewControllerWithIdentifier("NewMessage") as! NewMessageViewController
    newMessageViewController.participantIdentifiers = sourceViewController.participantIdentifiers
    newMessageViewController.licensePlate = sourceViewController.licensePlateLabel.text
    
    
    conversationViewController.conversation = nil
    conversationViewController.participantIdentifiers = sourceViewController.participantIdentifiers
    conversationListNavigationController.pushViewController(licensePlateVC, animated: false)
    conversationListNavigationController.pushViewController(newMessageViewController, animated: false)
    conversationListNavigationController.pushViewController(conversationViewController, animated: false)
    
    conversationViewController.sendInitMessage(sourceViewController.selectedMessage, licensePlate: sourceViewController.licensePlateLabel.text!)
    }
  
}


