//
//  ViewingViewController.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/20.
//

import UIKit
import AVKit

class ViewingViewController: UIViewController, OkutransDetectorDelegate
{
	let detector = OkutransDetector()
	
	var isDetection = false

	@IBOutlet weak var playerView: PlayerView!
	@IBOutlet weak var thumbnailImageView: UIImageView!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.detector.delegate = self
//		self.playerView.player = AVPlayer(playerItem: self.getPlayerItem(fileName: "movie"))
	}

	func getPlayerItem(fileName:String) -> AVPlayerItem?
	{
		guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") else
		{
			print("URL is nil")
			return nil
		}
		
		return AVPlayerItem(url: url)
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		self.detector.startDetection()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		
		self.detector.stopDetection()
	}
    
	func OkutransDetectorDidDetection(detector: OkutransDetector)
	{
		self.isDetection = true
		
		guard let player = self.playerView.player else {
			return
		}
		
		if (player.rate == 0.0)
		{
			player.play()
		}
	}
	
	func OkutransDetectorMagnitudeDidChange(detector: OkutransDetector, magnitude: Double)
	{
		if (self.detector.threshold > magnitude)
		{
			self.isDetection = false

			guard let player = self.playerView.player else {
				return
			}
			
			player.pause()
			player.seek(to: .zero)
		}
	}
	


}
