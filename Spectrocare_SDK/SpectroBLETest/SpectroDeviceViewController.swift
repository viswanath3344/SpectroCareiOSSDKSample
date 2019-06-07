//
//  SpectroDeviceViewController.swift
//  SpectroBLETest
//
//  Created by Ming-En Liu on 28/01/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit
import SpectroSDK

class SpectroDeviceViewController: UIViewController,UITextFieldDelegate,UITextViewDelegate {
    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       commandTextField.text = "$SWL1#"
       responseTextView.isEditable = false
       responseTextView.isScrollEnabled = true
       responseTextView.showsVerticalScrollIndicator = true
       NotificationCenter.default.addObserver(self, selector: #selector(receiveTestNotification(notification:)), name:  NOTIFICATION_DATA_AVAILABLE.name, object: nil)
       
        let leftButton = UIBarButtonItem(title: "Disconnect", style: .plain, target: self, action: #selector(disconnect))
        self.navigationItem.leftBarButtonItem = leftButton
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
//    @objc func disconnectTapped(){
//        SCConnection.sharedInstance.disconnectWithPeripheral()
//        self.navigationController?.popViewController(animated: true)
//    }
        @objc func disconnect(){
            SCConnection.sharedInstance.disconnectWithPeripheral()
            self.navigationController?.popViewController(animated: true)
        }
   
    @objc func receiveTestNotification(notification: NSNotification){
        if notification.name == NOTIFICATION_DATA_AVAILABLE.name{
            if let dict = notification.userInfo as? Dictionary<String, Any>{
                if let response = dict["response"] as? Data {
                    let responseString = SCConnectionHelper.sharedInstance.rawBuffer2Hex(buf: response)
                    DispatchQueue.main.async {
                        self.responseTextView.text = self.responseTextView.text.appending(responseString)
                        self.responseTextView.text = self.responseTextView.text.appending("\n")
                        self.responseTextView.scrollToBotom()
                    }
                }
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func sendAction(_ sender: Any) {
       
        SCConnection.sharedInstance.writeCommandToWatch(commandTextField.text!, {
            // Success
            DispatchQueue.main.async {
                self.view.makeToast("\(String(describing: self.commandTextField.text!)) command sent success !!!")
            }
            
        }) {
            // Failed
            self.view.makeToast("\(String(describing: self.commandTextField.text!)) command sent Failed !!!")
        }
    }
    
    @IBAction func clearAction(_ sender: Any) {
        responseTextView.text = ""
    }
}

class TextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 5)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

extension UITextView {
    
    func scrollToBotom() {
        let range = NSMakeRange(text.count - 1, 1);
        scrollRangeToVisible(range);
    }
    
}
