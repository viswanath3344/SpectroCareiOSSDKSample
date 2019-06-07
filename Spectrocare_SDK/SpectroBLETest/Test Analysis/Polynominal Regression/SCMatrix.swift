//
//  Matrix.swift
//  SpectroDevice
//
//  Created by Ming-En Liu on 07/08/18.
//  Copyright © 2018 Vedas labs. All rights reserved.
//

import UIKit

class SCMatrix: NSObject {

    func backwardSubstitution(anyMatrix:[[Double]], arr:[Double], row:Int, col:Int)  -> [Double] {
        var anyMatrix1 = anyMatrix
        var arr1 = arr
        if(row < 0 || col < 0){
            return arr1;
        } else{
            let rows = anyMatrix1.count
            let cols = anyMatrix1[0].count - 1
            var current:Double = 0
            var counter = 0
            
            for i in (col...cols-1).reversed()
            {
                if(i == col){
                    current = anyMatrix1[row][cols] / anyMatrix1[row][i]
                    
                } else{
                    anyMatrix1[row][cols] -= anyMatrix1[row][i] * arr1[rows - 1 - counter]
                    counter += 1 ;
                }
            }
            
            arr1[row] = current
            return self.backwardSubstitution(anyMatrix: anyMatrix1, arr: arr1, row: row - 1, col: col - 1);
        }
    }
    
    func combineMatrices(left:[[Double]],right:[Double]) -> [[Double]] {
        
        let rows = right.count
        let cols = left[0].count
        var returnMatrix = [[Double]]()
        
        for i in 0..<rows{
            returnMatrix.append(Array(repeating:0, count:cols+1))
            for j in 0...cols{
                if (j == cols) {
                    
                    returnMatrix[i][j] = right[i]
                    
                } else {
                    
                    returnMatrix[i][j] = left[i][j]
                }
            }
        }
        
        return returnMatrix;
    }
    
func forwardElimination(anyMatrix:[[Double]]) -> [[Double]] {
        let rows        = anyMatrix.count
        let cols        = anyMatrix[0].count
        var aMatrix     = Array(repeating:Array(repeating:0.0, count:cols), count:rows)
        //returnMatrix = anyMatrix;
        for i in 0..<rows{
            for j in 0..<cols{
                 aMatrix[i][j] = anyMatrix[i][j];
            }
        }
        
        for x in 0..<rows-1{
            for z in x..<rows-1{
                let numerator   = aMatrix[z + 1][x];
                let denominator = aMatrix[x][x];
                let result      = numerator / denominator;
                
                for i in 0..<cols{
                    aMatrix[z + 1][i] = aMatrix[z + 1][i] - (result * aMatrix[x][i]);
                }
            }
        }
        return aMatrix;
    }
    
    func gaussianJordanElimination(leftMatrix:[[Double]],rightMatrix:[Double]) -> [Double]  {
        
        let combined        = self.combineMatrices(left: leftMatrix, right: rightMatrix);
        var fwdIntegration  = self.forwardElimination(anyMatrix: combined);
        
        print("combined",combined)
        print("fwdIntegration",fwdIntegration)
        
        //NOW, FINAL STEP IS BACKWARD SUBSTITUTION WHICH RETURNS THE TERMS NECESSARY FOR POLYNOMIAL REGRESSION
        let arr = Array(repeating:0.0, count:fwdIntegration.count)
        
        
        return self.backwardSubstitution(anyMatrix: fwdIntegration, arr: arr, row: fwdIntegration.count-1, col: fwdIntegration[0].count-2)
    }
    
    func identityMatrix(anyMatrix:[[Int]]) -> [[Int]] {
        
        let rows = anyMatrix.count
        let cols = anyMatrix[0].count
        var identityMatrix = [[Int]]()
        
        for i in 0..<rows
        {
            for j in 0..<cols
            {
                if j == i
                {
                    identityMatrix[i][j] = 1
                }
                else
                {
                    identityMatrix[i][j] = 0
                }
                
            }
        }
        return identityMatrix;
    }
   
    
    func matrixProduct(matrix1:[[Int]], matrix2:[[Int]]) -> [[Int]]? {
        
        let numCols1 = matrix1[0].count;
        let numRows2 = matrix2.count;
        
        if(numCols1 != numRows2){
            return nil;
        }
        
        var product = [[Int]]()
        
        for row in 0..<numRows2
        {
            for col in 0..<numCols1
            {
                product[row][col] = self.doMultiplication(matrix1: matrix1, matrix2: matrix2, row: row,
                                                          col: col, numCol: numCols1);
            }
            
        }
        return product;
    }
    
    func doMultiplication (matrix1:[[Int]], matrix2:[[Int]], row:Int, col:Int, numCol:Int) -> Int{
        var counter = 0
        var result = 0
        while counter < numCol {
            result += matrix1[row][counter] * matrix2[counter][col];
            counter += 1
        }
        return result
    }
    
    func multiplyRow(anyMatrix:[[Int]], rowNum:Int, multiplier:Int) -> [[Int]] {
        
        let rows = anyMatrix.count;
        let cols = anyMatrix[0].count;
        var mMatrix = [[Int]]()
        
        for i in 0..<rows
        {
            for j in 0..<cols
            {
                if (i == rowNum) {
                    mMatrix[i][j] = anyMatrix[i][j] * multiplier;
                } else {
                    mMatrix[i][j] = anyMatrix[i][j];
                }
            }
        }
        return mMatrix;
    }
}
