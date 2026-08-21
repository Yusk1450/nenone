//
//  PlayerView.swift
//  OkutransTest
//
//  Created by ISHIGO Yusuke on 2024/06/01.
//

import UIKit
import AVKit

class PlayerView: UIView
{
	override class var layerClass: AnyClass {
		return AVPlayerLayer.self
	}
	
	var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer
	}
	
	var player: AVPlayer? {
		get {
			return playerLayer.player
		}
		
		set {
			playerLayer.player = newValue
		}
	}
}
