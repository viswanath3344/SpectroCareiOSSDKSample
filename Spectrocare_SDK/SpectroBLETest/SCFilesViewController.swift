//
//  SCFilesViewController.swift
//  SpectroBLETest
//
//  Created by Teja's MacBook on 26/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit
import MBProgressHUD
import SpectroSDK
//import JSSAlertView

class SCFilesViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var scFileTableView:UITableView!
    var isSelectedDevice:Bool!
    var backBtn = UIBarButtonItem()
    var refreshBtn = UIBarButtonItem()
   // var acitivityAlert:CustomAlert! = nil
    var selectedIndex : IndexPath?
     var hud:MBProgressHUD!
    var files = [SCFile]()

    override func viewDidLoad() {
        super.viewDidLoad()
        scFileTableView.rowHeight = UITableView.automaticDimension
        
       // navigationController?.navigationBar.isHidden = true
    
        files =  SCFileHelper.sharedInstance.getSCFiles()
        if files.count == 0 {
            self.refreshAction(self)
        }
        activateNotifications()
         customNavigationBar()
    }
    func customNavigationBar(){
        let viewForTitle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let listNameLabel = UILabel(frame: CGRect(x: 0, y: 3, width: 100, height: 40))
        listNameLabel.text = "SCFile"
        //Language.sharedInstance.get("View Cart", alter: nil)
        listNameLabel.textColor = UIColor.white
        listNameLabel.textAlignment = NSTextAlignment.center
        listNameLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        viewForTitle.addSubview(listNameLabel)
        self.navigationItem.titleView = viewForTitle
        let buttonIcon = UIImage(named: "left-arrow")
        backBtn =  UIBarButtonItem(title: "", style: UIBarButtonItem.Style.done, target: self, action: #selector(SCFilesViewController.backButtonAction(_:)))
        backBtn.image = buttonIcon
        backBtn.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem = backBtn
         let refreshIcon = UIImage(named: "refresh")
        refreshBtn = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.done, target: self, action: #selector(SCFilesViewController.refreshFiles(_:)))
        refreshBtn.image = refreshIcon
        refreshBtn.tintColor = UIColor.white
       
          self.navigationItem.rightBarButtonItem = refreshBtn
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = UIColor(red: 32/255, green: 132/255, blue: 173/255, alpha: 1.0)
    }
    @objc func backButtonAction(_ sender:UIBarButtonItem!){
        SCConnectionHelper.sharedInstance.disconnect()
        self.navigationController?.popViewController(animated: true)
    }
    @objc func refreshFiles(_ sender:UIBarButtonItem!){
        refreshAction(self)
    }
    func showProgressHud(){
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.label.text = "Loading..."
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  files.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SCCell", for: indexPath) as! SCFilesTableViewCell
        let jsonFileObject = files[indexPath.row]
        cell.fileNameLabel.text = jsonFileObject.filename.replacingOccurrences(of: ".json", with: "")
        cell.categoryLabel.text = jsonFileObject.category
        
        if let dateInDouble = Double(jsonFileObject.addedDate) {
          cell.dateLabel.text = getDateUsingTimeStamp(timestamp: dateInDouble)
        }
        if selectedIndex != nil{
            if (selectedIndex == indexPath) {
                cell.checkButton.isHidden = false
                cell.checkButton.setImage(UIImage(named:"ic_check"), for: .normal)
            }
            else{
                cell.checkButton.isHidden = true
            }
        }
        else{
            cell.checkButton.isHidden = true
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    
    func getDateUsingTimeStamp(timestamp:Double) -> String {
    
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "dd/MM/YYYY"
        let dateString = dateFormatter.string(from: date)
        
        return dateString
        
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        selectedIndex = indexPath
        self.isSelectedDevice = true
        tableView.reloadData()
    }
    
    func showAlertForNoInternet(){
        showAlert(title: "Alert", message: "No Internet Connection")
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.navigationBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextButton(_ sender: Any) {
       if isSelectedDevice == true{
            if InternetStatusClass.sharedInstance.isConnected{
            showAlertForForselection(indexPath: selectedIndex! as IndexPath)
            }
            else{
                showAlertForNoInternet()
            }
        }
        else{
            self.view.makeToast("Please select strip")
        }
       
        
        
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        if InternetStatusClass.sharedInstance.isConnected{
            showProgressHud()
            DispatchQueue.global(qos: .background).async {
                SCFileHelper.sharedInstance.getStripFiles() { (status,scFiles)  in
                    DispatchQueue.main.async {
                        self.hud.hide(animated: true)
                        if status {
                            if let files = scFiles {
                                self.files = files
                                self.scFileTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
        else{
            showAlertForNoInternet()
        }
        
    }
    
    @IBAction func fileSelectionAction(_ sender:Any){
     //   showFileSelectionActionSheet()
    }
    func showAlertForForselection(indexPath:IndexPath){
        let jsonFileObject = SCFileHelper.sharedInstance.scFiles[indexPath.row]
        let fileName = jsonFileObject.filename.replacingOccurrences(of: ".json", with: "")

       // let fileName = jsonFileObject.filename.replacingOccurrences(of: ".json", with: "")
        let alertview = UIAlertController(title: "Configure File", message: "Would you like to configure the \(fileName) into SpectroDevice", preferredStyle: .alert)
        
        let yesAction  =  UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { (action) in
            alertview.dismiss(animated: true, completion: nil)
            DispatchQueue.global(qos: .background).async {
                self.loadFileWithFileName(fileName: jsonFileObject.filename, category: jsonFileObject.category,date:jsonFileObject.addedDate)
            }
        }
        let noAction  = UIAlertAction(title: "No", style: .cancel) { (action) in
            alertview.dismiss(animated: true, completion: nil)
            self.isSelectedDevice = false
            self.selectedIndex = nil
            self.scFileTableView.reloadData()
        }
        alertview.addAction(noAction)
        alertview.addAction(yesAction)
        
        self.present(alertview, animated: true, completion: nil)
        
    }
    
    
    func loadFileWithFileName(fileName:String, category:String,date:String)  {
       
        DispatchQueue.main.async {
            self.showProgressHud()
           //self.view.makeToastActivity(.center)
        }
        SCTestAnalysis.sharedInstance.getDeviceSettings(testname: fileName, category: category) { (status) in
            DispatchQueue.main.async {
              // self.view.hideToastActivity()
                self.hud.hide(animated: true)
                if status{
                    
                    let VC = self.storyboard?.instantiateViewController(withIdentifier: "SCTesResultsViewController") as! SCTesResultsViewController
                    VC.category = category
                    VC.selectedFile = fileName
                    VC.addDate = date
                    self.navigationController?.pushViewController(VC, animated: true)
                }
                else{
                    self.showAlert(title: "Alert", message: "Download Failed")
                }
            }
            
        }
    }
    
    func showAlert(title:String,message:String)  {
        let alert = UIAlertController(title: title, message:message , preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

}
extension SCFilesViewController{
    
    private func activateNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(bleStatusRecieved(_:)), name: NOTIFICATION_BLE_STATUS, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnectionStatus(_:)), name: NOTIFICATION_CONNECTION_STATUS, object: nil)
    }
    
    private func deactivateNotifications(){
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_BLE_STATUS , object: nil)
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_CONNECTION_STATUS , object: nil)
        
    }
    
    @objc func bleStatusRecieved( _ notification:Notification){
        if let bleStatusDict =   notification.userInfo as? Dictionary<String, Bool>{
            _ = bleStatusDict["isAvaialable"] ?? false
            let isTurnOn = bleStatusDict["isTurnOn"] ?? false
            if !isTurnOn {
                DispatchQueue.main.async {
                    self.deactivateNotifications()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @objc func deviceConnectionStatus( _ notification:Notification){
        if let connnectionStatusDict =   notification.userInfo as? Dictionary<String, Bool>{
            let isConnected = connnectionStatusDict["status"] ?? false
            isConnected ? didDeviceConnect() : didDeviceDisconnect()
        }
    }
    
    func didDeviceConnect() {
        DispatchQueue.main.async {
            self.view.hideToastActivity()
        }
    }
    
    func didDeviceDisconnect() {
        DispatchQueue.main.async {
            self.view.hideToastActivity()
            let alert = UIAlertController(title: "Device disconnected...", message:"", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
                self.deactivateNotifications()
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
}
