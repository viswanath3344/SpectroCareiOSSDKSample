//
//  SpectroDeviceScanViewController.swift
//  SpectroBLETest
//
//  Created by Ming-En Liu on 29/01/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit
import Toast_Swift
import MBProgressHUD
import SpectroSDK

class SpectroDeviceScanViewController: UIViewController{
    
    @IBOutlet weak var devicesTableView: UITableView!
    var selectedIndex:Int = -1
    var devicesList = [SCDevice]()
    var noDataLabel = UILabel()
    var BlueoothAlertTimer:Timer?
    var hud:MBProgressHUD!
    var devicesNotFoundAlert:UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
       
//        let refreshButton = UIBarButtonItem(image: UIImage(named: "refresh"), style: .plain, target: self, action: #selector(refresh)) // action:#selector(Class.MethodName) for swift 3
//        self.navigationItem.rightBarButtonItem  = refreshButton
//        activateNotifications()
//        SCConnectionHelper.sharedInstance.startScan()
        
        
    }
    @objc func startScanning() {
        SCConnectionHelper.sharedInstance.startScan(refreshDuration: 5.0)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let viewForTitle = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 44))
        let listNameLabel = UILabel(frame: CGRect(x: 0, y: 3, width: 250, height: 40))
        listNameLabel.text = "Spectro BLE Devices"
        listNameLabel.textColor = UIColor.white
        listNameLabel.textAlignment = NSTextAlignment.center
        listNameLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        viewForTitle.addSubview(listNameLabel)
        self.navigationItem.titleView = viewForTitle
      
        let refreshButton = UIBarButtonItem(image: UIImage(named: "refresh"), style: .plain, target: self, action: #selector(refresh)) // action:#selector(Class.MethodName) for swift 3
        refreshButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem  = refreshButton
        
         navigationController?.navigationBar.barTintColor = UIColor(red: 32/255, green: 132/255, blue: 173/255, alpha: 1.0)
    }
    override func viewWillAppear(_ animated: Bool) {
        activateNotifications()
        startScanning()
        SCConnectionHelper.sharedInstance.configure()
        devicesList.removeAll()
        devicesTableView.reloadData()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deactivateNotifications()
    }
    
    func showProgressHud()
    {
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.hud.label.text = "Loading..."
    }
    
    
    private func activateNotifications(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(bleStatusRecieved(_:)), name: NOTIFICATION_BLE_STATUS, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newDeviceDiscovered(_:)), name: NOTIFICATION_NEW_DEVICE_DISCOVER, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnectionStatus(_:)), name: NOTIFICATION_CONNECTION_STATUS, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didDevicesNotFound(_:)), name: NOTIFICATION_DEVICE_NOTFOUND_STATUS, object: nil)
        
    }
    
    private func deactivateNotifications(){
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_BLE_STATUS , object: nil)
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_NEW_DEVICE_DISCOVER , object: nil)
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_CONNECTION_STATUS , object: nil)
        NotificationCenter.default.removeObserver(self, name:NOTIFICATION_DEVICE_NOTFOUND_STATUS , object: nil)
    }
    
    @objc func refresh()  {
        devicesList.removeAll()
        self.devicesTableView.reloadData()
        startScanning()
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func nextButonAction(_ sender: Any) {
    }
    
    func goToDeviceSettings(){
        let url = URL(string: "App-Prefs:root=Bluetooth") //for WIFI setting app
        let app = UIApplication.shared
        if app.canOpenURL(url!)
        {
            app.open(url!, options: [:], completionHandler: nil)
        }
    }
    
    
    
}

extension SpectroDeviceScanViewController:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if devicesList.count > 0{
            noDataLabel.isHidden = true
        }
        else{
            noDataLabel.isHidden = false
            noDataLabel   = UILabel(frame: CGRect(x: 0, y: 100, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "Device not found"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }
        
        return self.devicesList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SCDevicesTableViewCell
        let device = self.devicesList[indexPath.row]
        cell.textLabel?.text = device.name ?? "No Name"
        cell.detailTextLabel?.text = device.id ?? ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
       //self.view.makeToastActivity(.center)
        showProgressHud()
        selectedIndex = indexPath.row
        let device = self.devicesList[selectedIndex]
        
        
        SCConnection.sharedInstance.connectWithPeripheral(peripheral: device.peripheral!)
       
        tableView.reloadData()
           self.hud.hide(animated: true)
    }
}

extension SpectroDeviceScanViewController{
    
    @objc func bleStatusRecieved( _ notification:Notification){
        if let bleStatusDict =   notification.userInfo as? Dictionary<String, Bool>{
            let isAvaialble = bleStatusDict[bleAvailable] ?? false
            let isTurnOn = bleStatusDict[bleStatus] ?? false
            
            if isAvaialble && isTurnOn{  //Allow to scan  Mobile phone supports BLE and BLE powered on.
                SCConnectionHelper.sharedInstance.startScan()
            }
            else if !isTurnOn{
                DispatchQueue.main.async {
                    self.devicesList.removeAll()
                    self.devicesTableView.reloadData()
                    self.showTurnOnBluetoothAlert()
                }
            }
        }
    }
    
    @objc func newDeviceDiscovered(_ notification:Notification){
        DispatchQueue.main.async {
            self.devicesList = SCConnectionHelper.sharedInstance.getDevicesList()
            self.devicesTableView.reloadData()
        }
    }
    
    @objc func deviceConnectionStatus( _ notification:Notification){
        if let connnectionStatusDict =   notification.userInfo as? Dictionary<String, Bool>{
            let isConnected = connnectionStatusDict[connectionStatus] ?? false
            
            isConnected ? didDeviceConnect() : didDeviceDisconnect()
        }
    }
    
    
    func didDeviceConnect() {
        DispatchQueue.main.async {
            self.view.hideToastActivity()
            let objSpectroDevice = self.storyboard?.instantiateViewController(withIdentifier: "SCFilesViewController") as! SCFilesViewController
            self.navigationController?.pushViewController(objSpectroDevice, animated: true)
        }
    }
    
    func didDeviceDisconnect() {
        self.view.hideToastActivity()
        let alert = UIAlertController(title: "Connection Failed", message:"", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
            self.devicesTableView.reloadData()

        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func didDevicesNotFound(_ notification:Notification) {
        DispatchQueue.main.async {
            self.devicesList.removeAll()
            self.devicesTableView.reloadData()
            if self.devicesNotFoundAlert == nil{
                self.devicesNotFoundAlert = UIAlertController(title: "Devices Not Found", message:"Kindly check Devices and make sure the devices near by", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                self.devicesNotFoundAlert!.addAction(okAction)
                self.present(self.devicesNotFoundAlert!, animated: true, completion: nil)
            }
        }
    }
    
    private func showTurnOnBluetoothAlert(){
        let alert = UIAlertController(title: "Alert", message: "Turn on bluetooth", preferredStyle: UIAlertController.Style.alert)
        let Settings = UIAlertAction(title: "Settings", style: .default, handler:
        { alert -> Void in
            
            self.goToDeviceSettings()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler:
        { alert -> Void in
            
        })
        alert.addAction(Settings)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
}
