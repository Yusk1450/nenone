//
//  OkutransDetector.swift
//  OkutransTest
//
//  Created by ISHIGO Yusuke on 2024/06/01.
//

import UIKit
import CoreMotion

protocol OkutransDetectorDelegate : AnyObject
{
	func OkutransDetectorMagnitudeDidChange(detector:OkutransDetector, magnitude:Double)
	func OkutransDetectorDidDetection(detector:OkutransDetector)
}

class OkutransDetector: NSObject
{
	weak var delegate:OkutransDetectorDelegate?
	
	let cmManager = CMMotionManager()
	
//	var threshold = 2000.0
	var threshold = 110.0

	var fiterSize = 5
	var xVals = [Double]()
	var yVals = [Double]()
	var zVals = [Double]()
	
	override init()
	{
		super.init()
		
		self.cmManager.magnetometerUpdateInterval = 0.1
	}
	
	func startDetection()
	{
		self.cmManager.startMagnetometerUpdates(to: OperationQueue.main) { data, error in
			guard let magData = data?.magneticField else { return }
			
			self.xVals.append(magData.x)
			if (self.xVals.count > self.fiterSize)
			{
				self.xVals.removeFirst()
			}
			self.yVals.append(magData.y)
			if (self.yVals.count > self.fiterSize)
			{
				self.yVals.removeFirst()
			}
			self.zVals.append(magData.z)
			if (self.zVals.count > self.fiterSize)
			{
				self.zVals.removeFirst()
			}
			
			if (self.xVals.count < self.fiterSize)
			{
				return
			}
			
			let filteredX = self.getFilteredValue(vals: self.xVals)
			let filteredY = self.getFilteredValue(vals: self.yVals)
			let filteredZ = self.getFilteredValue(vals: self.zVals)
			
			let mag = sqrt(pow(filteredX, 2) + pow(filteredY, 2) +  pow(filteredZ, 2))
			print(mag)
			self.delegate?.OkutransDetectorMagnitudeDidChange(detector: self, magnitude: mag)
			
			if (mag > self.threshold)
			{
				self.delegate?.OkutransDetectorDidDetection(detector: self)
			}
		}
	}
	
	func stopDetection()
	{
		self.cmManager.stopMagnetometerUpdates()
	}
	
	func getFilteredValue(vals:[Double]) -> Double
	{
		let sortedVals = vals.sorted()
		if (sortedVals.count % 2 == 0)
		{
			return (sortedVals[sortedVals.count / 2 + 1] + sortedVals[sortedVals.count / 2]) / 2.0
		}
		else
		{
			return sortedVals[sortedVals.count / 2]
		}
	}
}
