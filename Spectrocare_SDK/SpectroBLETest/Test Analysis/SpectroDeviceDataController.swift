//
//  JsonDataController.swift
//  MutliDivisionTableView
//
//  Created by Ming-En Liu on 25/09/18.
//  Copyright © 2018 Vedas labs. All rights reserved.
//

import UIKit




struct IntensityChart {
    var testName:String
    var pixelMode:Bool
    var originalMode:Bool
    var autoMode:Bool
    var xAxisArray:[Double]
    var yAxisArray:[Double]
    var substratedArray:[Double]
    var wavelengthArray:[Double]
    var criticalWavelength:Double
}

 struct ReflectanceChart {
    var testName:String
    var xAxisArray:[Double]
    var yAxisArray:[Double]
    var criticalWavelength:Double
    var autoMode:Bool
    var interpolationValue:Double
}

struct ConcentrationControl {
    var SNo:String
    var testItem:String
    var concentration:String
    var units:String
    var referenceRange:String
}

let darkSpectrumTitle = "Dark Spectrum"
let standardWhiteTitle = "Standard White (Reference)"
let JSON_FETCH_URL = "http://54.210.61.0:8096"


struct SpectorDeviceDataStruct:Decodable {
    var modifiedDate:String
    var deviceInformation:[DeviceInformationStruct]?
    var spectrumDisplayRegionInPixel:[Int]?
    var spectrumDisplayRegionInWavelength:[Int]?
    var baselineRegionInPixel:[Int]?
    var baselineRegionInWavelength:[Int]?
    var imageSensor :ImageSensorStruct
    var wavelengthCalibration:WavelengthCalibration
    var stripControl:StripControl
    var RCTable:[RCTableData]?
    var wifiDetails:WifiDetails
    var stripMeasurment:StripMeasurmentStruct?
    var lEDInfo:[LEDInfo]?
}

struct StripMeasurmentStruct:Decodable {
    var stepDistanceInMM:Double
    var stepCountForOppositeDirection:Int
    var extraStepCountForEject:Int
    var measureItems:[MeasureItemsStruct]
}

struct MeasureItemsStruct:Decodable {
    
    var testName:String
    var distance:Double
    var distanceUnit:String
    var steps:Int
}

struct ImageSensorStruct:Decodable {
    
    var ROI:[Int]
    var exposureTime:Int
    var exposureMinTime:Int
    var exposureMaxTime:Int
    
    var analogGain:Int
    var analogGainMinTime:Int
    var analogGainMaxTime :Int
    
    var digitalGain:Double
    var digitalGainMinValue:Double
    var digitalGainMaxValue:Double
    
    var noOfAverage:Int
    var noOfAverageMin:Int
    var noOfAverageMax:Int
    
    var noOfAverageForDarkSpectrum:Int
    var noOfAverageMinForDarkSpectrum:Int
    var noOfAverageMaxForDarkSpectrum:Int
    
    
}

struct DeviceInformationStruct:Decodable {
    var title:String
    var description:String
    var id:Int
}
struct WavelengthCalibration:Decodable {
    var noOfCoefficients:Int
    var coefficients:[Double]
}

struct StripControl:Decodable {
    var distanceFromPostionSensorToSpectroMeterInMM:Double
    var distanceFromHolderEdgeTo1STStripInMM:Double
    var distancePerStepInMM:Double
    var steps:[Steps]
}

struct WifiDetails:Decodable {
    var ssid:String
    var password:String
    var iPAddress:String
    var port:Int
}


struct Steps:Decodable {
    var stripIndex:Int
    var testName:String
    var noOfSteps:Int
    var distanceInMM:Double
    var direction:String
    var dwellTimeInSec:Int
    var standardWhiteIndex:Int
    var noOfAverage:Int
}

struct RCTableData:Decodable {
    var stripIndex:Int
    var testItem : String
    var unit:String
    var referenceRange:String
    var criticalwavelength:Double
    var R:[Double]
    var C:[Double]
    var limitLineRanges:[LimetLineRanges]
    var numberFormat:String
    
}
struct LimetLineRanges:Decodable {
    var sno:Int
    var lineSymbol:String
    var CMinValue:Double
    var CMaxValue:Double
    var rMinValue:Double
    var rMaxValue:Double
}
struct LEDInfo:Decodable {
    var originalName:String
    var modifiedName:String
    var status:Int
}

class SpectroDeviceDataController: NSObject {

   private var spectroDeviceObject:SpectorDeviceDataStruct?
    
    class var sharedInstance: SpectroDeviceDataController {
        struct Singleton {
            static let instance = SpectroDeviceDataController()
        }
        return Singleton.instance
    }
    
    private override init() {
        super.init()
      //  requestCommand = ""
    }
    
    func setupTestParameters(_ fileName:String,_ category:String,statusCallBack: @escaping (_ isLoaded: Bool, _ spectrodeviceObject:SpectorDeviceDataStruct?) -> Void) {
        
        guard let serviceUrl = URL(string: FETCH_FILES_DATA_STRING) else {
            statusCallBack(false, nil)
            return
            
        }
        let parameterDictionary = ["username" : "viswa","filename":fileName]
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            statusCallBack(false, nil)
            return
        }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard let data = data else{
                statusCallBack(false,nil)
                return
            }
            do {
              
             let jsonWithObjectRoot = try? JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonWithObjectRoot as? [String: Any] {
                    if let status = dictionary["response"] as? String {
                        if status == "0" {
                               statusCallBack(false,nil)
                               return
                        }
                    }
                
                 }
                let decoder = JSONDecoder()
                //  decoder.keyDecodingStrategy = .convertFromSnakeCase  // replace _
                
                let webSiteDescriptionObject = try decoder.decode(SpectorDeviceDataStruct.self, from: data)
                self.spectroDeviceObject = webSiteDescriptionObject
                if self.spectroDeviceObject != nil {
                    //  self.motorSteps = spectroDevice.stripControl.steps
                    self.updateMotorSteps()
                    statusCallBack(true, self.spectroDeviceObject)
                }
            }
            catch let jsonError{
                statusCallBack(false,nil)
                print("JsonParsing Error \(jsonError)")
            }
            }.resume()
        
    }
   
    func loadJSONDataFromUrl(path:URL,statusCallBack: @escaping (_ isLoaded: Bool, _ spectrodeviceObject:SpectorDeviceDataStruct?) -> Void) {
        
        do {
            let data = try Data(contentsOf: path, options: .mappedIfSafe)
            do {
                let decoder = JSONDecoder()
                //  decoder.keyDecodingStrategy = .convertFromSnakeCase  // replace _
                
                let webSiteDescriptionObject = try decoder.decode(SpectorDeviceDataStruct.self, from: data)
                self.spectroDeviceObject = webSiteDescriptionObject
                if self.spectroDeviceObject != nil {
                  //  self.motorSteps = spectroDevice.stripControl.steps
                    self.updateMotorSteps()
                    statusCallBack(true, self.spectroDeviceObject)
                }
            }
            catch let jsonError
            {
                print("JsonParsing Error \(jsonError)")
                statusCallBack(false, nil)
                
            }
            
        } catch {
            // handle error
            statusCallBack(false, nil)
        }
        
    }

    func loadJsonDataFromUrl(fileName:String,statusCallBack: @escaping (_ isLoaded: Bool, _ spectrodeviceObject:SpectorDeviceDataStruct?) -> Void){
        
        if let data =  UserDefaults.standard.value(forKey: fileName)  {
            if let jsonData  =  data as? Data {
                do {
                    let decoder = JSONDecoder()
                    //  decoder.keyDecodingStrategy = .convertFromSnakeCase  // replace _
                    
                    let webSiteDescriptionObject = try decoder.decode(SpectorDeviceDataStruct.self, from: jsonData)
                    self.spectroDeviceObject = webSiteDescriptionObject
                    if let spectroDevice = self.spectroDeviceObject {
                        print(spectroDevice.deviceInformation ?? "")
                        print(spectroDevice.imageSensor.analogGain)
                        print(spectroDevice.imageSensor.digitalGain)
                        print(spectroDevice.imageSensor.exposureTime)
                        print(spectroDevice.imageSensor.noOfAverage)
                        print(spectroDevice.imageSensor.ROI)
                      //  self.motorSteps = spectroDevice.stripControl.steps
                        self.updateMotorSteps()
                        statusCallBack(true, self.spectroDeviceObject)
                    }
                }
                catch let jsonError{
                    print("JsonParsing Error \(jsonError)")
                    statusCallBack(false, nil)
                    
                }
            }
        }
        else{
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let decoder = JSONDecoder()
                    //  decoder.keyDecodingStrategy = .convertFromSnakeCase  // replace _
                    
                    let webSiteDescriptionObject = try decoder.decode(SpectorDeviceDataStruct.self, from: data)
                    self.spectroDeviceObject = webSiteDescriptionObject
                    if let spectroDevice = self.spectroDeviceObject {
                        print(spectroDevice.deviceInformation!)
                        print(spectroDevice.imageSensor.analogGain)
                        print(spectroDevice.imageSensor.digitalGain)
                        print(spectroDevice.imageSensor.exposureTime)
                        print(spectroDevice.imageSensor.noOfAverage)
                        print(spectroDevice.imageSensor.ROI)
                      //  self.motorSteps = spectroDevice.stripControl.steps
                        self.updateMotorSteps()
                        let defaults = UserDefaults.standard
                        defaults.set(data, forKey: fileName)
                        UserDefaults.standard.synchronize()
                        statusCallBack(true, self.spectroDeviceObject)
                    }
                    
                    
                }
                catch let jsonError{
                    print("JsonParsing Error \(jsonError)")
                    statusCallBack(false,nil)
                }
                
            } catch {
                // handle error
                statusCallBack(false,nil)
            }
        }
       }
    }
   
    
    func updateMotorSteps()  {
        guard  var motorSteps = spectroDeviceObject?.stripControl.steps else {
            return
        }
        for i in  0 ..< motorSteps.count {
            if  let objMotorStep = calculateTheRealDistanceStpesAndDirectionForTestItem(position:i, motorSteps: motorSteps){  //  Calculated  Motor step success
                motorSteps[i] = objMotorStep
            }
        }
           self.spectroDeviceObject?.stripControl.steps = motorSteps
    }
    
    func calculateTheRealDistanceStpesAndDirectionForTestItem(position:Int,motorSteps:[Steps]) -> Steps?  {
        
        var tempObjMotorStep = motorSteps[position]
        
        if position == 0{  // Handle the First object by adding required values
            let psToSpectroMeasureObject = getStripMeasureObjectForItem(itemName:"positionSensorToSpectrometer")
            let psToStripMeasureObject = getStripMeasureObjectForItem(itemName:"stripHolderToStrip")
            let testItemMeasureObject = getStripMeasureObjectForItem(itemName:tempObjMotorStep.testName)
            if psToSpectroMeasureObject != nil && psToStripMeasureObject != nil && testItemMeasureObject != nil{
                let finalMotroStepValue =  psToStripMeasureObject!.steps+testItemMeasureObject!.steps-psToSpectroMeasureObject!.steps
                let finalDistanceValue =   psToStripMeasureObject!.distance+testItemMeasureObject!.distance-psToSpectroMeasureObject!.distance
                var direction = "CCW"
                if finalMotroStepValue < 0{
                    direction = "CW"
                }
                tempObjMotorStep.direction = direction
                tempObjMotorStep.noOfSteps = abs(finalMotroStepValue)
                tempObjMotorStep.distanceInMM = abs(finalDistanceValue)
                return tempObjMotorStep
            }
            return nil
        }
        else{
            if position == motorSteps.count-1{
                // Last Position  It's for Eject
                let prevMotorStep =  motorSteps[position-1]
                let prevTestItemMeasureObject = getStripMeasureObjectForItem(itemName:prevMotorStep.testName)
                let psToStripMeasureObject = getStripMeasureObjectForItem(itemName:"stripHolderToStrip")
                let stepDistanceInMM =  getDistanceForStep()
                let extraStepsForEject = getExtraStepCountForEject()
                
                if prevTestItemMeasureObject != nil  && psToStripMeasureObject != nil && stepDistanceInMM != nil && extraStepsForEject != nil {
                    let extraDistance = Double(extraStepsForEject!)*stepDistanceInMM!
                    let finalMotroStepValue =  psToStripMeasureObject!.steps+prevTestItemMeasureObject!.steps+extraStepsForEject!
                    let finalDistanceValue =   psToStripMeasureObject!.distance+prevTestItemMeasureObject!.distance+extraDistance
                    let direction = "CW"  // Here strip is already inside , So need to clock wise direction to eject strip.
                    tempObjMotorStep.direction = direction
                    tempObjMotorStep.noOfSteps = Int(abs(finalMotroStepValue))
                    tempObjMotorStep.distanceInMM = abs(finalDistanceValue)
                    return tempObjMotorStep
                }
                else {
                    return nil
                }
            }
            else {
                let prevMotorStep =  motorSteps[position-1]
                let prevTestItemMeasureObject = getStripMeasureObjectForItem(itemName:prevMotorStep.testName)
                let nowTestItemMeasureObject = getStripMeasureObjectForItem(itemName:tempObjMotorStep.testName)
                let stepDistanceInMM =  getDistanceForStep()
                let motorStepsForOppositeDirection = getStepCountForOppsiteDirection()
                if prevTestItemMeasureObject != nil && nowTestItemMeasureObject != nil  && stepDistanceInMM != nil && motorStepsForOppositeDirection != nil {
                    var finalMotroStepValue =  nowTestItemMeasureObject!.steps-prevTestItemMeasureObject!.steps
                    var finalDistanceValue =   nowTestItemMeasureObject!.distance-prevTestItemMeasureObject!.distance
                    var direction = "CCW"
                    if finalMotroStepValue < 0{
                        direction = "CW"
                    }
                    finalMotroStepValue = abs(finalMotroStepValue)
                    finalDistanceValue = abs(finalDistanceValue)
                    if direction != prevMotorStep.direction{
                        finalMotroStepValue = finalMotroStepValue + Int(motorStepsForOppositeDirection!)
                        finalDistanceValue =  finalDistanceValue + Double(motorStepsForOppositeDirection!)*stepDistanceInMM!
                    }
                    tempObjMotorStep.direction = direction
                    tempObjMotorStep.noOfSteps = finalMotroStepValue
                    tempObjMotorStep.distanceInMM = finalDistanceValue
                    return tempObjMotorStep
                }
                return nil
                
            }
        }
        
    }
    
    func getStripMeasureObjectForItem(itemName:String) -> MeasureItemsStruct? {
        if let measureItemsSets = spectroDeviceObject?.stripMeasurment?.measureItems{
            for objMeasureItem in measureItemsSets{
                if objMeasureItem.testName == itemName{
                    return objMeasureItem
                }
            }
        }
        return nil
    }
    
    func getDistanceForStep() -> Double? {
        return  spectroDeviceObject?.stripMeasurment?.stepDistanceInMM ?? nil
    }
    
    func getStepCountForOppsiteDirection() -> Int? {
        return  spectroDeviceObject?.stripMeasurment?.stepCountForOppositeDirection ?? nil
    }
    
    func getExtraStepCountForEject() -> Int? {
        return  spectroDeviceObject?.stripMeasurment?.extraStepCountForEject ?? nil
    }
}
