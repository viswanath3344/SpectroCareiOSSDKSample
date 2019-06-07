//
//  Correlation.swift
//  SpectroDevice
//
//  Created by Ming-En Liu on 07/08/18.
//  Copyright © 2018 Vedas labs. All rights reserved.
//

import UIKit

class SCCorrelation: NSObject {

    var x:[Double]!
    var y:[Double]!
    
     init(x:[Double],y:[Double]) {
        self.x = x
        self.y = y
    }
    
    
    
    func  correlationCoefficient()   {
        
    }
    
    func diffFromAvg() -> Double  {
        var sum:Double = 0
        for i in 0..<self.x.count
        {
            sum += (self.x[i] - self.avg(aList: self.x)) * (y[i] - self.avg(aList: self.y));
        }
        return sum
    }
    
    func avg(aList:[Double]) -> Double {
        var sum:Double = 0.0
        
        for i in 0..<aList.count
        {
            sum += aList[i]
        }
        return sum/Double(aList.count)
        
    }
    
    func diffFromAvgSqrd(aList:[Double])  -> Double {
        var sum:Double = 0;
        for i in 0..<aList.count
        {
            sum += pow((aList[i]-self.avg(aList: aList)), 2)
        }
        return sum;
    }
    
    
    
    func stdv(aList:[Double]) -> Double {
       return sqrt(self.diffFromAvgSqrd(aList: aList)/Double(aList.count-1))
    }
    
    func b0()  -> Double {
        
        return self.avg(aList: self.y) - self.b1() * self.avg(aList: self.x);
    }
    
    func b1() -> Double {
        
        return self.diffFromAvg() / self.diffFromAvgSqrd(aList: self.x);
    }
    
    func sumList(aList:[Double]) -> Double {
        
        var sum:Double = 0;
        for i in 0..<aList.count
        {
            sum += aList[i]
        }
        return sum;
    }
    
    func sumSquares(aList:[Double]) -> Double {
        var sum:Double = 0;
        for i in 0..<aList.count
        {
            sum += pow(aList[i], 2)
        }
        return sum;
    }
    
    func sumXTimesY() -> Double {
        var sum:Double = 0;
        for i in 0..<self.x.count{
            sum += (self.y[i] * self.x[i])
        }
        return sum;
    }
    
    func linearRegression(independentVariable:Double) -> Double {
        return self.b1() * independentVariable + self.b0();
    }
    
}
