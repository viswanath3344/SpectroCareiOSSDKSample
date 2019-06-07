//
//  SCTestResult.swift
//  SpectroBLETest
//
//  Created by Ming-En Liu on 03/04/19.
//  Copyright © 2019 Vedas labs. All rights reserved.
//

import Foundation

public class TestFactors {
   public var SNo:String?
   public var testname:String?
    public var value:String?
    public var units:String?
   public var referenceRange:String?
    public var flag:Bool?
    public var result:String?
    
    init(SNo:String, testname:String, value:String, units:String, referenceRange:String, flag:Bool, result:String) {
        self.SNo = SNo
        self.testname = testname
        self.value = value
        self.units = units
        self.referenceRange = referenceRange
        self.flag = flag
        self.result = result
    }
    
}
