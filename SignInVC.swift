//
//  ViewController.swift
//  gadew
//
//  Created by Slumreaper on 1/8/17.
//  Copyright © 2017 RA1NROUGE. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController {
  
  @IBOutlet weak var emailField: FancyField!
  @IBOutlet weak var pwdField: FancyField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if let _ = KeychainWrapper.defaultKeychainWrapper.string(forKey: KEY_UID){
      print("User: ID found in keychain")
      performSegue(withIdentifier: "goToFeed", sender: nil)
    }
  }
  
  @IBAction func facebookBtnTapped(_ sender: AnyObject) {
    
    let facebookLogin = FBSDKLoginManager()
    
    facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
      if error != nil {
        print("User: Unable to authenticate with Facebook - \(error)")
      } else if result?.isCancelled == true {
        print("User: User cancelled Facebook authentication")
      } else {
        print("User: Successfully authenticated with Facebook")
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        self.firebaseAuth(credential)
      }
    }
    
  }
  
  func firebaseAuth(_ credential: FIRAuthCredential) {
    FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
      if error != nil {
        print("User: Unable to authenticate with Firebase - \(error)")
      } else {
        print("User: Successfully authenticated with Firebase")
        if let user = user {
          let userData = ["provider": credential.provider]
          self.completeSignIn(id: user.uid, userData: userData)
        }
      }
    })
  }
  @IBAction func signInTapped(_ sender: AnyObject) {
    if let email = emailField.text, let pwd = pwdField.text {
      FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
        if error == nil {
          print("User: Email user authenticated with Firebase")
          if let user = user {
            let userData = ["provider": user.providerID]
            self.completeSignIn(id: user.uid, userData: userData)
          }
        } else {
          FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
            if error != nil {
              print("User: Unable to authenticate with Firebase using email")
            } else {
              print("User: Successfully authenticated with Firebase")
              if let user = user {
                let userData = ["provider": user.providerID]
                self.completeSignIn(id: user.uid, userData: userData)
              }
            }
          })
        }
      })
    }
  }
  
  func completeSignIn(id: String, userData: Dictionary<String, String>) {
    DataService.ds.createFirbaseDBUser(uid: id, userData: userData)
    //let keychainResult = KeychainWrapper.setString(id, forKey: KEY_UID)
    let keychainResult = KeychainWrapper.defaultKeychainWrapper.set(id, forKey: KEY_UID)
    print("User: Data saved to keychain \(keychainResult)")
    performSegue(withIdentifier: "goToFeed", sender: nil)
  }
  
}

