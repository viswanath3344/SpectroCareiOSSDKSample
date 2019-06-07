//
//  PolynomialRegression1.swift
//  SpectroDevice
//
//  Created by Ming-En Liu on 07/08/18.
//  Copyright © 2018 Vedas labs. All rights reserved.
//

import UIKit

struct DataPoint {
    var x:Double
    var y:Double
}

class SCPolynomialRegression: NSObject {
    
    var data:[DataPoint]!
    var matrix:SCMatrix!
    var degree: Int!
    var leftMatrix:[[Double]]!
    var rightMatrix:[Double]!

    init(theData:[DataPoint],degrees:Int) {
        self.data = theData
        self.degree = degrees
        self.matrix      =  SCMatrix();
        //self.leftMatrix  = []
        //self.rightMatrix = []
    }
    
    
    func fillMatrix()  {
        generateLeftMatrix()
        generateRightMatrix()
        
    }
    
    
    
    func sumX(anyData:[DataPoint],power:Double) -> Double {
        var sum:Double = 0
        
        for i in 0..<anyData.count
        {
             sum += pow(anyData[i].x, power)
        }
        return sum
    }
    
    func sumXTimesY(anyData:[DataPoint],power:Double) -> Double {
        var sum:Double = 0
        
        for i in 0..<anyData.count
        {
            sum += pow(anyData[i].x, power) * anyData[i].y
        }
        return sum
    }
    
    func sumY(anyData:[DataPoint],power:Double) -> Double {
        var sum:Double = 0
        
        for i in 0..<anyData.count
        {
            sum += pow(anyData[i].y, power)
        }
        return sum
    }
    
    func generateLeftMatrix()  {
        
        leftMatrix = [[Double]]()
        
        for i in 0...self.degree
        {
            leftMatrix.append(Array(repeating:0, count:self.degree+1))
            for j in 0...self.degree
            {
                if i==0 && j==0
                {
                    self.leftMatrix[i][j] = Double(self.data.count)
                }
                else
                {
                    self.leftMatrix[i][j] = self.sumX(anyData: data, power: Double(i+j))
                }
            }
        }
    
        print("Left Matrix",leftMatrix)
        
    }
    
    func generateRightMatrix()  {
        
        rightMatrix =  Array(repeating:0, count:self.degree+1)
        for i in 0...self.degree
        {
            if i == 0
            {
                self.rightMatrix[i] = self.sumY(anyData: data, power: 1)
            }
            else
            {
                self.rightMatrix[i] = self.sumXTimesY(anyData: data, power: Double(i))
            }
        }
        
        print("Right Matrix",rightMatrix)
        
    }
    
    func predictY(terms:[Double] ,x:Double) -> Double {
        
        var result:Double = 0
        
        for i in (0...terms.count-1).reversed()
        {
            if i == 0
            {
                result += terms[i]
            }
            else
            {
                result += terms[i] * pow(x, Double(i))
            }
        }
        return result
        
    }
    
    func linearRegression(y:[Double],x:[Double]) ->  [String:Double] {
        
        var lr = [String:Double]()
        let n = Double(y.count)
        var sum_x:Double = 0
        var sum_y:Double = 0
        var sum_xy:Double = 0
        var sum_xx:Double = 0
        var sum_yy:Double = 0
        
        for i in  0..<y.count
        {
            sum_x += x[i];
            sum_y += y[i];
            sum_xy += (x[i]*y[i]);
            sum_xx += (x[i]*x[i]);
            sum_yy += (y[i]*y[i]);
        }
        
        let exp1:Double  = n*sum_xy - sum_x*sum_y
        let exp2:Double = sqrt((n*sum_xx-sum_x*sum_x)*(n*sum_yy-sum_y*sum_y))
        let exp3:Double = exp1/exp2
        lr["r2"] = pow(exp3, 2)
        
       return lr
         //lr['r2'] = Math.pow((n*sum_xy - sum_x*sum_y)/Math.sqrt((n*sum_xx-sum_x*sum_x)*(n*sum_yy-sum_y*sum_y)),2);
    }
    
    
    /*
 
     var actualData = [], regressionData = [], someData = [];
     
     for(var i = 0; i < 100; i++){
     var x = i;
     var randomY = getRandomInt(5, 20);
     someData.push(new DataPoint(x, randomY));
     actualData.push({x: x, y: randomY});
     }
     
     var poly = new PolynomialRegression(someData, degree);
     var terms = poly.getTerms();
     
     console.log(terms);
     
     actualData.forEach(function(data){
     regressionData.push({x: data.x, y: poly.predictY(terms, data.x)});
     });
     
     console.log(actualData);
     console.log(regressionData);
     
     return {actual : actualData, regression : regressionData}
 
     */
    
    func getRandomInt(min:UInt32,max:UInt32) -> UInt32 {
        
        return arc4random_uniform(UInt32(max))+min;
    }
    
    
    func getTerms() ->[Double]  {
       return self.matrix.gaussianJordanElimination(leftMatrix: self.leftMatrix, rightMatrix: self.rightMatrix)
    }
    

}
