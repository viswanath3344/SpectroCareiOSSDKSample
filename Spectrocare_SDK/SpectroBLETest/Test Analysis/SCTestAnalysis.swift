//
//  TestAnalysis.swift
//  SpectrumHuman
//
//  Created by Ming-En Liu on 21/03/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import UIKit


public typealias TestAnalysisStatusCallback = (Bool, [TestFactors]?) -> Void
public typealias SyncStatusCallback = (Bool) -> Void

public class SCTestAnalysis:NSObject {
   // private override init ()  {}
    
    public var testAnalysisCallback:TestAnalysisStatusCallback?
    public var syncStatusCallback:SyncStatusCallback?
    private var connnectionStatusCallback:SyncStatusCallback?
    
    public var testItems:[TestFactors]!
    
    private var intensityChartsArray = [IntensityChart]()
    private var reflectenceChartsArray = [ReflectanceChart]()
    private var concentrationArray = [ConcentrationControl]()
    
    private var stripNumber  = 0
    private var isForDarkSpectrum = false
    
    //  var motorSteps = [Steps]()
    private var pixelXAxis = [Double]()
    private var wavelengthXAxis = [Double]()
    private var intensityArray = [Double]()
    
    private var darkSpectrumIntensityArray = [Double]()
    private var standardWhiteIntensityArray = [Double]()
    
    private var hexaDecimalArray = [String]() // For Hexadecimal values , Does't need in real time. It's for testing purpose only.
    
    private var isForSync  = false
    private var commandNumber = 0
    private var requestCommand:String!
    private var motorSteps:[Steps]!
    var spectroDeviceObject:SpectorDeviceDataStruct?
    public static let sharedInstance = SCTestAnalysis()
    
    
//    public class var sharedInstance: SCTestAnalysis {
//        struct Singleton {
//            static let instance = SCTestAnalysis()
//        }
//        return Singleton.instance
//    }
//
    
    override init (){
        super.init()
        testItems = [TestFactors]()
        loadDefaultSpectrodeviceObject()
        //_ = setUpSpectroDeviceforTestItem(testname: JSonFileNames.no5_3518_urineTest.rawValue, callback)
        NotificationCenter.default.addObserver(self, selector: #selector(intenisityDataRecieved), name: NOTIFICATION_INTENSITY_DATA_AVAILABLE.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataRecieved), name: NOTIFICATION_DATA_AVAILABLE.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectionStatusReceieved), name: NOTIFICATION_CONNECTION_STATUS, object: nil)
    }
    
    
    public func canDo() -> Bool{
        return SCConnectionHelper.sharedInstance.isConnected
    }
    
    @objc func connectionStatusReceieved(_ notification: NSNotification)  {
        if  let messageDict = notification.userInfo as? Dictionary<String, Any>{
            if let status =  messageDict["status"] as? Bool{
            if(self.connnectionStatusCallback != nil){
               self.connnectionStatusCallback!(status)
                }
                if status{
                   // Device Connected.
                }
                else {
                      if self.syncStatusCallback != nil{   // When disconnect 
                            self.syncStatusCallback!(false)
                             self.syncDone()
                        }
                    if self.testAnalysisCallback != nil{
                        self.testAnalysisCallback!(false, nil)
                        self.testAnalysisCallback = nil
                    }
                }
            }
        }
    }
    
    
    
    private func loadDefaultSpectrodeviceObject(){
     SpectroDeviceDataController.sharedInstance.loadJsonDataFromUrl(fileName: JSonFileNames.no5_3518_urineTest.rawValue) { (status, object) in
            if status{
            self.spectroDeviceObject = object
                if let steps = self.spectroDeviceObject?.stripControl.steps {
                    self.motorSteps = steps
                }
            }
        }
    }
    public func getDeviceSettings(testname:String,category:String, statusCallback:@escaping SyncStatusCallback)  {
        
        SpectroDeviceDataController.sharedInstance.setupTestParameters(testname, category) {
                (status,object)  in
                if status{
                    self.spectroDeviceObject = object
                    if let steps = self.spectroDeviceObject?.stripControl.steps {
                        self.motorSteps = steps
                    }
                }
                statusCallback(status)
            }
    }
    
     func deviceConnectionOnChanged(statusCallback:@escaping SyncStatusCallback)  {
        self.connnectionStatusCallback = statusCallback
        
        
    }

   public func startTestAnalysis(callback:@escaping TestAnalysisStatusCallback) {
        self.testAnalysisCallback = callback
         self.clearPreviousTestResulsArray()
             loadPixelArray()
             reprocessWavelength()
             prepareChartsDataForIntensity()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // do stuff 42 seconds later
            self.getDarkSpectrum()
        }
        
            //self.perform(#selector(self.getDarkSpectrum), with: self, afterDelay: 2)
    }
    
    
    
    
    
    func stopTestAnalysis() {
        self.testAnalysisCallback = nil
    }
    
    public func syncSettingsWithDevice(statusCallback:@escaping SyncStatusCallback){
        self.syncStatusCallback = statusCallback
        if SCConnectionHelper.sharedInstance.isConnected{
            if !isForSync{
                isForSync = true
                commandNumber = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // do stuff 42 seconds later
                   self.sendCommandForROIParams()
                }
               
            }
    }
    }
    
    @objc private func intenisityDataRecieved(_ notification: NSNotification){
        
        if  let messageDict = notification.userInfo as? Dictionary<String, Any>{
            if let response = messageDict["response"] as? Data{
                let byteArray = [UInt8](response)
                if(processIntensityValues(data: byteArray)){
                    if !isForDarkSpectrum{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.motorStepsControl(motorObject: self.motorSteps[self.stripNumber])
                        }
                    }
                    else{
                        isForDarkSpectrum = false
                        print("Dark Intensity Data recieved")
                        stripNumber = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        SCConnectionHelper.sharedInstance.prepareCommandForMoveToPosition()

                        }
                    }
                }
                else{
                    // Data mismatch,  Resend for Intensity getting.
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                        self.requestCommand = ""
                        SCConnectionHelper.sharedInstance.getIntensity()
                    })
                }
            }
        }
    }
    
//    @objc private func intenisityDataRecieved(_ notification: NSNotification){
//
//        if  let messageDict = notification.userInfo as? Dictionary<String, Any>{
//                if let response = messageDict["response"] as? Data{
//                    let byteArray = [UInt8](response)
//                     processIntensityValues(data: byteArray)
//                    if !isForDarkSpectrum{
//                         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            self.motorStepsControl(motorObject: self.motorSteps[self.stripNumber])
//                        }
//                    }
//                    else{
//                         isForDarkSpectrum = false
//                        print("Dark Intensity Data recieved")
//                         stripNumber = 0
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        SCConnectionHelper.sharedInstance.prepareCommandForMoveToPosition()
//                        }
//                    }
//                }
//        }
//    }
    
    @objc func dataRecieved(_ notification: NSNotification)  {
        
        if  let messageDict = notification.userInfo as? Dictionary<String, Any>{
            if let request =  messageDict["request"] as? String{
                if let response = messageDict["response"] as? Data{
                    processResponseData(command: request, data: response)
                    
                }
            }
        }
    }
    
    public func testCompleted() {
        SCConnectionHelper.sharedInstance.clearCache()
        SCConnectionHelper.sharedInstance.disconnect()
        processRCConversion()
        self.testItems.removeAll()
        for object in  concentrationArray{
            var flag = false
            var resultText = ""
            var finalValue = object.concentration
            if let value = Double(finalValue){
                flag = self.getFlagForTestItemWithValue(testName: object.testItem, value: value)
                resultText =  self.getResultTextForTestItemwithValue(testName: object.testItem, value: value)
                finalValue = self.getNumberFormatStringforTestNameWithValue(testName: object.testItem, value: value)
            }
            let objectTestItem = TestFactors(SNo: object.SNo, testname: object.testItem, value: finalValue, units: object.units, referenceRange: object.referenceRange, flag: flag, result: resultText)
            self.testItems.append(objectTestItem)
        }
        
        self.testAnalysisCallback!(true,self.testItems)
        self.testAnalysisCallback = nil
    }
    
    private  func processResponseData(command:String, data:Data)  {
        //   let rootView = UIApplication.shared.keyWindow
        if data.count > 0{
            if let response = String(bytes: data, encoding: .utf8) {
                print(response)
                if response.contains("OK"){
                    //   hideProgressActivityWithSuccess()
                    if  isForSync{
                        switch  commandNumber {
                        case 1:
                            sendExposureTime()
                        case 2:
                            sendAnanlogGain()
                        case 3:
                            sendDigitalGain()
                        case 4:
                            sendSpectrumAVG()
                        case 5:
                            // Process End
                            self.syncStatusCallback!(true)
                            self.syncDone()
                            
                            
                        default:
                            self.syncStatusCallback!(false)
                            self.syncDone()
                            break
                        }
                        commandNumber =  commandNumber+1
                    }
                    else{
                        
                        DispatchQueue.main.async {
                            //    self.view.makeToast("\(String(describing: self.requestCommand)) command Success")
                            if command == LED_TURN_ON{
                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                                    self.stripNumber = 0
                                    self.performMotorStepsFunction()
                                })
                            }
                            else if command == LED_TURN_OFF{
                                self.testCompleted()
                                
                            }
                            
                        }
                    }
                    
                }
                else if response.contains("POS"){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.ledControl(true)
                    }
                }
                else if response.contains("STP"){
                    print("StripNumberMonitor:\( stripNumber)")
                    if  stripNumber !=  motorSteps.count-1{
                        let dwellTime = Int( motorSteps[ stripNumber].dwellTimeInSec)
                        print("Waited DwellTime:\(dwellTime)")
                        print("Strip Number:\( stripNumber)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(dwellTime), execute: {
                            self.requestCommand = ""
                            self.stripNumber += 1
                            SCConnectionHelper.sharedInstance.getIntensity()
                        })
                    }
                    else{
                        print("Steps are completed")
                        stripNumber = 0
                        ledControl(false)
                    }
                    
                }
                else if response.uppercased().contains("ERR"){
                    if  isForSync{
                        isForSync = false
                        SCConnectionHelper.sharedInstance.clearCache()
                        self.syncStatusCallback!(false)
                    }else{
                        self.testAnalysisCallback?(false,nil)
                        clearPreviousTestResulsArray()
                    }
                    
                }
            }
            
        }
    }
    private func syncDone() {
        commandNumber = 0
        isForSync = false
        SCConnectionHelper.sharedInstance.clearCache()
        syncStatusCallback = nil
    }
    
    @objc private func getDarkSpectrum(){
        isForDarkSpectrum = true
        stripNumber = 1
        SCConnectionHelper.sharedInstance.getIntensity()
    }
    
    private func prepareChartsDataForIntensity(){
        intensityArray.removeAll()
        intensityChartsArray.removeAll()
        if let rcTableArray = spectroDeviceObject?.RCTable{
            
            for objRcTable in rcTableArray{
                let objIntensity = IntensityChart(testName: objRcTable.testItem, pixelMode: true, originalMode: true, autoMode: true, xAxisArray:pixelXAxis, yAxisArray: [], substratedArray: [], wavelengthArray:wavelengthXAxis, criticalWavelength: objRcTable.criticalwavelength)
                intensityChartsArray.append(objIntensity)
            }
            
// If needed to show dark spectrum and Standard White spectrum Then use below methods
            
            
            let objSWIntensity = IntensityChart(testName: standardWhiteTitle, pixelMode: true, originalMode: true, autoMode: true, xAxisArray: pixelXAxis, yAxisArray: [], substratedArray: [], wavelengthArray: wavelengthXAxis, criticalWavelength: 0.0)
            
            intensityChartsArray.append(objSWIntensity)
            
            
            let objDarkIntensity = IntensityChart(testName: darkSpectrumTitle, pixelMode: true, originalMode: true, autoMode: true, xAxisArray: pixelXAxis, yAxisArray: [], substratedArray: [], wavelengthArray: wavelengthXAxis, criticalWavelength: 0.0)
            intensityChartsArray.append(objDarkIntensity)
            
        }
    }
    
    private func processRCConversion ()  {
        
        reflectenceChartsArray.removeAll()
        
        if  let swSubstratedArray  =  getStandardwhiteSubstrateArray(){
            for objIntensitychartObject in intensityChartsArray{
                if objIntensitychartObject.testName != standardWhiteTitle  && objIntensitychartObject.testName != darkSpectrumTitle{
                    let originalArray = getOriginalDivReference(originalArray: objIntensitychartObject.substratedArray, referenceArray: swSubstratedArray)
                    
                    let interpolationValue  = getClosestValue(xValues: objIntensitychartObject.wavelengthArray, yValues: originalArray, criticalWavelength: objIntensitychartObject.criticalWavelength)
                    let objReflectanceChart = ReflectanceChart(testName: objIntensitychartObject.testName , xAxisArray:wavelengthXAxis, yAxisArray: originalArray, criticalWavelength: objIntensitychartObject.criticalWavelength, autoMode: true, interpolationValue: interpolationValue)
                    reflectenceChartsArray.append(objReflectanceChart)
                }
            }
        }
        else{
            print("No SW avaialble")
        }
        
        processFinalTestResults()
    }
    
    private func processFinalTestResults()  {
        
        concentrationArray.removeAll()
        var index = 1
        
        for objReflectance in  reflectenceChartsArray
        {
            if  let rcTableObject = getRCObjectFortestName(testName: objReflectance.testName)
            {
                let finalC = getClosestValue(xValues: rcTableObject.R, yValues: rcTableObject.C, criticalWavelength: objReflectance.interpolationValue)
                let objConcetration = ConcentrationControl.init(SNo: "\(index)", testItem: objReflectance.testName, concentration: "\(finalC)", units: rcTableObject.unit, referenceRange: rcTableObject.referenceRange)
                concentrationArray.append(objConcetration)
                index += 1
            }
        }
        print(concentrationArray)
    }
    
    private func getRCObjectFortestName(testName:String) -> RCTableData? {
        
        if let rcTable = spectroDeviceObject?.RCTable{
            for objRCTable in rcTable
            {
                if objRCTable.testItem == testName
                {
                    return objRCTable
                }
            }
        }
        return nil
    }
    
    private func getStandardwhiteSubstrateArray() -> [Double]?  {
        
        for objIntensitychartObject in intensityChartsArray
        {
            if objIntensitychartObject.testName == standardWhiteTitle {
                
                return objIntensitychartObject.substratedArray
            }
        }
        return  nil
    }
    
    private func getClosestValue(xValues:[Double],yValues:[Double], criticalWavelength:Double) -> Double {
        
        // Sorting array based on Difference
        
        let sortedArrayBasedOnDifference =  xValues.sorted { (one, two) -> Bool in
            
            return abs(criticalWavelength-one) > abs(criticalWavelength - two)
        }
        
        print(sortedArrayBasedOnDifference)
        let firstXValue = sortedArrayBasedOnDifference.last!
        let secondXValue = sortedArrayBasedOnDifference[sortedArrayBasedOnDifference.count-2]
        
        let firstYValue = yValues[xValues.firstIndex(of: firstXValue)!]
        let secondYValue = yValues[xValues.firstIndex(of: secondXValue)!]
        
        var x1 = firstXValue
        var x2 = secondXValue
        var y1 = firstYValue
        var y2 = secondYValue
        
        if x1 > x2{
            x1 = secondXValue
            x2 = firstXValue
            y1 = secondYValue
            y2 = firstYValue
        }
        
        print("firstXValue:\(firstXValue)")
        print("criticalWavelength:\(criticalWavelength)")
        print("secondValue:\(secondXValue)")
        
        print("X1:\(x1)")
        print("X2:\(x2)")
        print("Y1:\(y1)")
        print("Y2:\(y2)")
        
        
        let finalY  =  y1 + ((criticalWavelength-x1)*(y2-y1))/(x2-x1)
        
        return finalY
    }
    

   private func motorStepsControl(motorObject:Steps)  {
    
       var direction = MOVE_STRIP_COUNTER_CLOCKWISE_TAG
    
        if motorObject.direction == "CW"{
            direction = MOVE_STRIP_CLOCKWISE_TAG
        }
    
    SCConnectionHelper.sharedInstance.prepareCommandForMotorMove(steps: motorObject.noOfSteps, direction: direction)
    }
    
     func getFlagForTestItemWithValue(testName:String,value:Double) -> Bool {
        var isOk = false
        if let RCTable = spectroDeviceObject?.RCTable {
            for objRC in RCTable{
                if objRC.testItem == testName{
                    
                    if  let safeRange = objRC.limitLineRanges.first{
                        
                        if  value > safeRange.CMinValue && value <= safeRange.CMaxValue{
                            isOk = true
                            return isOk
                        }
                    }
                    
                }
                
            }
        }
        return isOk
        
    }
    
    func getResultTextForTestItemwithValue(testName:String,value:Double) -> String {
        
        if let RCTable = spectroDeviceObject?.RCTable {
            for objRC in RCTable{
                if objRC.testItem == testName{
                    
                    for objLimitRange in objRC.limitLineRanges{
                        
                        if value > objLimitRange.CMinValue && value <= objLimitRange.CMaxValue{
                            return objLimitRange.lineSymbol
                        }
                    }
                }
                
            }
        }
        
        return ""
        
    }
    
    func getNumberFormattedString(value:Double,format:String) -> String {
        var formattedString = "\(value)"
        switch format {
        case "X":
            formattedString = String(format: "%.0f", value)
        case "X.X":
            formattedString = String(format: "%.1f", value)
        case "X.XX":
            formattedString = String(format: "%.2f",value)
        case "X.XXX":
            formattedString =  String(format: "%.3f", value)
        case "X.XXXX":
            formattedString =  String(format: "%.4f", value)
        default:
            formattedString =  "\(value)"
        }
        
        formattedString = String(format: "%g", Double(formattedString) ?? formattedString)
        
        return formattedString
    }
    
    func getNumberFormatStringforTestNameWithValue(testName:String,value:Double) -> String {
        
        var formattedString = "\(value)"
        
        if let rcTable =  spectroDeviceObject?.RCTable{
            
            for objRCTable in rcTable{
                if objRCTable.testItem == testName{
                    formattedString =  getNumberFormattedString(value: value, format: objRCTable.numberFormat)
                    break
                }
            }
        }
        
        return formattedString
        
    }
    
    
    @objc private func performMotorStepsFunction(){
        motorStepsControl(motorObject: motorSteps[stripNumber])
    }
    
    private func ledControl(_ isOn: Bool){
        SCConnectionHelper.sharedInstance.prepareCommandForLED(isOn: isOn)
    }

    
    private func processIntensityValues(data:[UInt8]) -> Bool {
        
        var responseData = data
        
        // Getting Starting Header of Command response.
        if String(bytes: responseData[0...5], encoding: .utf8) != nil{
            //  print(startingCommnd)
        }
        // Removing Starting Header part from Bytes Array
        responseData.removeSubrange(0...5)
        
        // Getting Ending Header of Command response.
        if let endingCommand  = String(bytes: responseData[responseData.count-5...responseData.count-1], encoding: .utf8){
            print(endingCommand)
        }
        // Removing Ending Header part from Bytes Array
        responseData.removeSubrange(responseData.count-5...responseData.count-1)
        
        
        var startIndex  = 0
        let readingBytesCount = 4   // reading every 2 bytes
        
        
        if responseData.count/readingBytesCount != pixelXAxis.count {
            print("Data mismatched")
            return false
        }
        
        // Getting Intesity values between starting header and ending header.
     
        // For Intesity values
        
        hexaDecimalArray.removeAll()
        intensityArray.removeAll()
        
        // Iterating response data for read 2 bytes each time.
        while (responseData.count-readingBytesCount) >= startIndex {
            //   print(responseData[startIndex...startIndex+1])  // For testing purpose
            let twoBytesData =  Data.init(bytes: responseData[startIndex..<startIndex+readingBytesCount]) // Getting two bytes and creating data object using those bytes
            let twobytesHexaString = twoBytesData.hexEncodedString() // Converting Data  to heaxdecimalString
            
            hexaDecimalArray.append(twobytesHexaString)   // Adding to hexa decimal array . It's for testing purpose only.
            //  print(twobytesHexaString)  // For testing purpose
            
            // print(intensityValue)   // For testing purpose
            let intensityValue  = twobytesHexaString.hexaToFloat  // Converting hexadecimal to decimal
            intensityArray.append(Double(intensityValue))   // Adding to intensity array
            
            //            let intensityValue  = twobytesHexaString.hexaToFloat  // Converting hexadecimal to decimal
            //            intensityArray.append(Double(intensityValue))
            
            startIndex  = startIndex+readingBytesCount  // Increasing starting index for read next two bytes.
        }
        
        if isForDarkSpectrum{
            darkSpectrumIntensityArray = intensityArray
            print("DarkSpectrum Taken")
            if let  position = getPositionForTilte(title: darkSpectrumTitle){
                var object = intensityChartsArray[position]
                object.yAxisArray = darkSpectrumIntensityArray
                intensityChartsArray[position] = object
            }
        }
        else{
            self.setIntensityArrayForTestItem()
        }
        
        return true
    }
    
    
   private func setIntensityArrayForTestItem() {
        
        let currentObject =  motorSteps[stripNumber-1]
        
        print("Called Intesity method:\(stripNumber-1)")
        
        if currentObject.standardWhiteIndex == 0{
            
            for i in 0..<self.intensityChartsArray.count{
                var object = intensityChartsArray[i]
                if object.testName == currentObject.testName{
                    
                    object.yAxisArray = self.intensityArray
                    object.substratedArray = getSubstratedArray(spectrumIntensityArray: self.intensityArray, darkSpectrumIntensityArray: self.darkSpectrumIntensityArray)
                    intensityChartsArray[i] = object
                    return
                }
            }
        }
        else{
            standardWhiteIntensityArray = self.intensityArray
            
            if let  position = getPositionForTilte(title: standardWhiteTitle){
                var object = intensityChartsArray[position]
                object.yAxisArray = standardWhiteIntensityArray
                object.substratedArray = getSubstratedArray(spectrumIntensityArray: standardWhiteIntensityArray, darkSpectrumIntensityArray: darkSpectrumIntensityArray)
                intensityChartsArray[position] = object
            }
            
        }
        
        if stripNumber == motorSteps.count-1 {
            
            // Testing ended.
            
        }
    }
    
   private func getPositionForTilte(title:String) -> Int? {
        
        for i in 0..<self.intensityChartsArray.count{
            let object = intensityChartsArray[i]
            
            if object.testName == title{
                return i
            }
        }
        
        return nil
    }
    
   private func getSubstratedArray(spectrumIntensityArray:[Double], darkSpectrumIntensityArray:[Double]) -> [Double] {
        
        var substratedArray = [Double]()
        
        for i in 0..<spectrumIntensityArray.count{
            substratedArray.append(spectrumIntensityArray[i]-darkSpectrumIntensityArray[i])
        }
        return substratedArray
    }
    
    
   private func loadPixelArray()  {
        pixelXAxis.removeAll()
        let pixelCount = spectroDeviceObject?.imageSensor.ROI[1] ?? 1280
        for i in 1...pixelCount{
            pixelXAxis.append(Double(i))
        }
        
    }
    
   private func reprocessWavelength(){
        //reprocess wavelength calculation
        //build terms
        wavelengthXAxis = pixelXAxis
        if let wavelengthCalibration =  spectroDeviceObject?.wavelengthCalibration{
            //wavelengthCalcVal
            self.wavelengthXAxis.removeAll()
            let poly =  SCPolynomialRegression(theData: [], degrees: wavelengthCalibration.noOfCoefficients)
            poly.fillMatrix()
            
            for xx in  0..<pixelXAxis.count{
                self.wavelengthXAxis.append(round((poly.predictY(terms: wavelengthCalibration.coefficients, x: self.pixelXAxis[xx])) * 100) / 100);
            }
            print(wavelengthXAxis)
        }
    }
    
    
   private func getOriginalDivReference(originalArray:[Double],referenceArray:[Double]) -> [Double] {
        
        var divisionArray = [Double]()
        
        for i in 0..<originalArray.count
        {
            divisionArray.append(originalArray[i]/referenceArray[i])
        }
        
        return divisionArray
        
    }
    
   private func sendCommandForROIParams()  {
        if SCConnectionHelper.sharedInstance.isConnected{
            if let ROIvaluesArray = spectroDeviceObject?.imageSensor.ROI{
                SCConnectionHelper.sharedInstance.prepareCommandForROI(ho: Int(ROIvaluesArray.first!), hc: Int(ROIvaluesArray[1]), vo: Int(ROIvaluesArray[2]), vc: Int(ROIvaluesArray.last!))
            }
        }
        else{
            //UIApplication.shared.keyWindow?.makeToast("Device not connected !!!")
        }
    }
    
    
   private func sendSpectrumAVG()  {
        if SCConnectionHelper.sharedInstance.isConnected {
            if let darkSpectrumAvg = spectroDeviceObject?.imageSensor.noOfAverageForDarkSpectrum{
                SCConnectionHelper.sharedInstance.prepareCommandForNoOfAverage(count: Int(darkSpectrumAvg))
            }
        }
        else{
           // UIApplication.shared.keyWindow?.makeToast("Device not connected !!!")
        }
    }
    
   private func sendExposureTime()  {
        
        if SCConnectionHelper.sharedInstance.isConnected {
            if let expousure = spectroDeviceObject?.imageSensor.exposureTime{
                SCConnectionHelper.sharedInstance.prepareCommandForExpousureCount(count: Int(expousure))
            }
        }
        else{
           // UIApplication.shared.keyWindow?.makeToast("Device not connected !!!")
        }
        
        
        
    }
    
   private func sendAnanlogGain() {
        
        if SCConnectionHelper.sharedInstance.isConnected {
            if let analogValue = spectroDeviceObject?.imageSensor.analogGain{
                SCConnectionHelper.sharedInstance.prepareCommandForAnalogGain(analogValue: "\(analogValue)X")
            }
        }
        else{
           // UIApplication.shared.keyWindow?.makeToast("Device not connected !!!")
        }
        
        
    }
    
   private func sendDigitalGain() {
        
        if SCConnectionHelper.sharedInstance.isConnected {
            if let digitGainDouble =  spectroDeviceObject?.imageSensor.digitalGain{
                SCConnectionHelper.sharedInstance.prepareCommandForDigitalGain(digitalGainValue: digitGainDouble)
            }
        }
        else{
          //  UIApplication.shared.keyWindow?.makeToast("Device not connected !!!")
        }
        
        
    }
    
    
   private func clearPreviousTestResulsArray(){
        intensityChartsArray.removeAll()
        reflectenceChartsArray.removeAll()
        concentrationArray.removeAll()
        stripNumber = 0
    }
    

}
