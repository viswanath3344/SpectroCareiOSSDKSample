//
//  SCFileHelper.swift
//  SpectroBLETest
//
//  Created by Ming-En Liu on 03/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit



struct JSONFilesResponse:Decodable {
    var response:String
    var files:[SCFile]
}
struct SCFile:Decodable {
    var filename:String
    var  id:String
    var addedDate:String
    var category:String
}

class SCFileHelper: NSObject {
    var scFiles = [SCFile]()
    
    class var sharedInstance : SCFileHelper{
        struct Singleton{
            static let instance = SCFileHelper()
        }
        return Singleton.instance
    }
    
    private override init(){
        super.init()
    }
    
    func getSCFiles()->[SCFile]  {
        return scFiles
    }
    
    func getStripFiles(statusCallBack: @escaping (_ isLoaded: Bool) -> Void){
       
        guard let serviceUrl = URL(string: FETCH_FILES_URL_STRING) else { statusCallBack(false);return  }
        let parameterDictionary = ["username" : "viswanath3344@gmail.com"]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            statusCallBack(false)
            return
        }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard let data = data else{
                statusCallBack(false)
                return
            }
            do {
                let decoder = JSONDecoder()
                //  decoder.keyDecodingStrategy = .convertFromSnakeCase  // replace _
                let structureObject = try decoder.decode(JSONFilesResponse.self, from: data)
                if structureObject.response == "3"{
                    self.scFiles = structureObject.files
                    print(self.scFiles)
                }
                statusCallBack(true)
            }
            catch let jsonError{
                statusCallBack(false)
                print("JsonParsing Error \(jsonError)")
                
            }
            }.resume()
    }
    
    func loadStripDataFromfileName(fileName:String,statusCallBack: @escaping (_ isLoaded: Bool, _ spectrodeviceObject:SpectorDeviceDataStruct?) -> Void) {

    }
    
}
