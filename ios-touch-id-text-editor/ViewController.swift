//
//  ViewController.swift
//  ios-touch-id-text-editor
//
//  Created by Adam Goth on 8/28/17.
//  Copyright © 2017 Adam Goth. All rights reserved.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var textpad: UITextView!

    @IBOutlet weak var unlockButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set notifications so textpad can be adjusted when keyboard is toggled
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveTextpad), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        //customize the unlock button
        unlockButton.layer.cornerRadius = 5
        unlockButton.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1.0)
        unlockButton.setTitleColor(UIColor.black, for: .normal)
        unlockButton.layer.borderWidth = 1
        unlockButton.layer.borderColor = UIColor.black.cgColor
        
        title = "Touch ID Textpad"
        
    }
    
    func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        //gets keyboard's frame in a cgRect
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        //hide insets if keyboard is disappearing, else set the bottom inset to the size of the keyboard
        if notification.name == NSNotification.Name.UIKeyboardWillHide {
            textpad.contentInset = UIEdgeInsets.zero
        } else {
            textpad.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        //get insets for the scroll
        textpad.scrollIndicatorInsets = textpad.contentInset
        
        //scroll to wherever the text entry cursor is located
        let selectedRange = textpad.selectedRange
        textpad.scrollRangeToVisible(selectedRange)
        
    }

    func unlockTextpad() {
        //unhides text pad, changes title, adds a done button for saving
        textpad.isHidden = false
        title = "Edit Mode"
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveTextpad))
        self.navigationItem.rightBarButtonItem = done
        
        //loads text from keychain using wrapper, defaults if first time use
        if let text = KeychainWrapper.standardKeychainAccess().string(forKey: "lockedText") {
            textpad.text = text
        } else {
            textpad.text = "This is a locked textpad. Update the text and then press Done to save it. You will need to unlock it with Touch ID to view it again."
        }
    }
    
    func saveTextpad() {
        //make sure textpad is actively shown
        if !textpad.isHidden {
            //remove done button
            self.navigationItem.rightBarButtonItem = nil
            
            //save text to keychain using wrapper
            _ = KeychainWrapper.standardKeychainAccess().setString(textpad.text, forKey: "lockedText")
            
            //remove keyboard, hide textpad, and change title back
            textpad.resignFirstResponder()
            textpad.isHidden = true
            title = "Touch ID Textpad"
            
            //present message that text has been saved
            let ac = UIAlertController(title: "Text Saved", message: "Your text has been saved. Unlock to edit again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }

    @IBAction func authenticateTapped(_ sender: Any) {
        //get context for local authentication kit
        let context = LAContext()
        var error: NSError?
        
        //check if device has touch ID on it
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Use Touch ID to unlock this textpad"
            
            //present reason fingerprint is needed
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success, authenticationError) in
                
                //make sure we are on the main thread since we are updating UI
                DispatchQueue.main.async {
                    if success {
                        self.unlockTextpad()
                    }
                }
            }
        } else {
            //present an alert if the device does not have touch ID
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
}

