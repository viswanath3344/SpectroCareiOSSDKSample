//
//  SCTesResultsViewController.swift
//  SpectroBLETest
//
//  Created by Teja's MacBook on 26/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit
import MBProgressHUD
import SpectroSDK

class SCTesResultsViewController: UIViewController {
    @IBOutlet weak var categoryName: UILabel!
    
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var addedDate: UILabel!
    @IBOutlet weak var stripName: UILabel!
    @IBOutlet weak var abortButton: UIButton!

    var  selectedFile = String()
    var category = String()
    var addDate = String()
     var DateFormat = DateFormatter()
    var backButton = UIBarButtonItem()
    var startBtn = UIBarButtonItem()
      var hud:MBProgressHUD!
    var testResults = [TestFactors]()

    override func viewDidLoad() {
        super.viewDidLoad()
       
        //addedDate.text = addDate
       resultsTableView.rowHeight = UITableView.automaticDimension
        categoryName.text = category
        stripName.text = selectedFile
        
        let timeStamp = addDate.components(separatedBy: ".")
        var strDate = String()
        if (timeStamp.count) > 0
                {
                 strDate = timeStamp[0]
                  
                }
            let addDT = Double(strDate)
      
        let date = Date(timeIntervalSince1970: addDT!)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "dd/MM/YYYY"
        let addTime = dateFormatter.string(from: date)
      
        addedDate.text = addTime
        costomNavigationBar()
        abortButton.layer.borderWidth = 1
        abortButton.layer.borderColor = UIColor(red: 3/255, green: 66/255, blue: 91/255, alpha: 1.0).cgColor
        abortButton.layer.cornerRadius = 5
    }
    func costomNavigationBar()
    {
        let viewForTitle = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let listNameLabel = UILabel(frame: CGRect(x: -25, y: 3, width: 160, height: 40))
        listNameLabel.text = "SCTestResult"
        //Language.sharedInstance.get("View Cart", alter: nil)
        listNameLabel.textColor = UIColor.white
        listNameLabel.textAlignment = NSTextAlignment.center
        listNameLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        viewForTitle.addSubview(listNameLabel)
        self.navigationItem.titleView = viewForTitle
        let buttonIcon = UIImage(named: "left-arrow")
        backButton =  UIBarButtonItem(title: "", style: UIBarButtonItem.Style.done, target: self, action: #selector(SCTesResultsViewController.backButtonAction(_:)))
        backButton.image = buttonIcon
        backButton.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem = backButton
        
//        startBtn = UIBarButtonItem(title: "Start", style: UIBarButtonItem.Style.done, target: self, action: #selector(SCTesResultsViewController.startRighSideBarButtonItemTapped(_:)))
//        startBtn.tintColor = UIColor.white
        let syncButton = UIBarButtonItem(title: "start",  style: UIBarButtonItem.Style.done, target: self, action: #selector(SCTesResultsViewController.startRighSideBarButtonItemTapped(_:)))
           syncButton.tintColor = UIColor.white
//        navigationItem.rightBarButtonItems = [startBtn, syncButton]
        self.navigationItem.rightBarButtonItem = syncButton
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = UIColor(red: 32/255, green: 132/255, blue: 173/255, alpha: 1.0)
        
    }
    @objc func backButtonAction(_ sender:UIBarButtonItem!){
        //navigationController?.navigationBar.isHidden = false
       self.navigationController?.popViewController(animated: true)
        
    }
    @objc func startRighSideBarButtonItemTapped(_ sender:UIBarButtonItem!){
        startSyncing()
    }
//@objc func syncRighSideBarButtonItemTapped(_ sender:UIBarButtonItem!){
//        startSyncing()
//        }
    func showProgressHud(title:String){
        if self.hud != nil{
            self.hud.hide(animated: false)
        }
        self.hud = MBProgressHUD.showAdded(to: self.resultsTableView, animated: true)
        self.hud.label.text = title
    }
    
    
    func startTesting(){
        if SCTestAnalysis.sharedInstance.canDo(){
            DispatchQueue.main.async {
                //self.view.makeToastActivity(.center)
                self.showProgressHud(title: "Analyzing...")
            }
            SCTestAnalysis.sharedInstance.startTestAnalysis { (status, results, error) in
                DispatchQueue.main.async {
                    // self.view.hideToastActivity()
                    self.hud.hide(animated: true)
                    if status{
                        if let results = results{
                            print(results)
                            self.testResults = results
                            self.navigationController?.navigationBar.isUserInteractionEnabled = true
                            self.view.makeToast("Testing Completed")
                            self.resultsTableView.reloadData()
                            self.abortButton.isHidden = true
                        }
                        // Testings is done and got results
                    }else if (error != nil){
                        self.showAlert(title:"Alert",message:error!["message"]! as! String)
                        self.view.makeToast(error!["message"]! as? String)
                    }
                    else{
                        self.showAlert(title:"Alert",message:"Testing Failed")
                        self.view.makeToast("Testing Failed")
                    }
                }
            }
        }
        
    }
    
    func startSyncing()  {
        if SCTestAnalysis.sharedInstance.canDo() {
            //self.view.makeToastActivity(.center)
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            showProgressHud(title: "Configuring settings...")
            self.abortButton.isHidden = false
            SCTestAnalysis.sharedInstance.syncSettingsWithDevice { (status) in
                DispatchQueue.main.async {
                    //self.view.hideToastActivity()
                    self.hud.hide(animated: true)
                    if status{
                        self.startTesting()
                        self.view.makeToast("Syncing is done", duration: 5, position: .bottom)
                    }
                    else{
                        self.showAlert(title:"Alert",message:"Testing Failed")
                        self.view.makeToast("Syncing is failed", duration: 5, position: .bottom)
                    }
                }
            }
            
        }
    }
    
    func showAlert(title:String,message:String)  {
        
        let alert = UIAlertController(title: title, message:message , preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Retry", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
            self.startSyncing()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(okAction)
          alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        
    }

   
    @IBAction func backButton(_ sender: Any) {
        //navigationController?.navigationBar.isHidden = false
       
    }
    @IBAction func abortButtonAction(_ sender: Any) {
        
        let alertController  = UIAlertController.init(title: "Alert", message: "Do you want to abort the test?", preferredStyle: UIAlertController.Style.alert)
        
        let noAction = UIAlertAction.init(title: "No", style: UIAlertAction.Style.cancel) { (UIAlertAction) in
            alertController.dismiss(animated: true, completion: nil)
            
        }
        let yesAction = UIAlertAction.init(title: "Yes", style: UIAlertAction.Style.default) { (UIAlertAction) in
            alertController.dismiss(animated: true, completion: nil)
            self.navigationController?.navigationBar.isUserInteractionEnabled = false
            self.showProgressHud(title: "Aborting...")
            SCTestAnalysis.sharedInstance.abortTesting(statusCallback: { (status) in
                DispatchQueue.main.async {
                    self.hud.hide(animated: true)
                    self.view.makeToast("Abort is done ")
                    self.abortButton.isHidden = true
                    if status{
                        self.navigationController?.navigationBar.isUserInteractionEnabled = true
                    }
                }
                
            })
            
        }
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
extension SCTesResultsViewController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  testResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestResultsTableViewCell")as! TestResultsTableViewCell
        let objTestITem = testResults[indexPath.row]
        cell.sNo.text = objTestITem.SNo
        cell.testName.text = objTestITem.testname
        let objValue = objTestITem.value!
        let objResult = objTestITem.result!
        let objunit = objTestITem.units!
        cell.ResultValueAndunits.text =  objValue + "   " + objunit + "   " + objResult
        return cell
    }


}
