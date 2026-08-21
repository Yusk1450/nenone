//
//  PlayViewController.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/20.
//

import UIKit

class PreviewViewController: UIViewController
{
	var currentIndex: Int = 0
	var images = [UIImage]()
	
	var timer: Timer?

    override func viewDidLoad()
	{
        super.viewDidLoad()

		var index = 10
		for image in self.images.reversed()
		{
			let imageView = UIImageView(frame: self.view.bounds)
			imageView.image = image
			imageView.tag = index
			imageView.contentMode = .scaleAspectFill
			imageView.clipsToBounds = true
			imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.view.addSubview(imageView)
			
			index += 1
		}
		
		self.currentIndex = 10 + self.images.count - 1
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		self.timer = Timer.scheduledTimer(timeInterval: 1.0,
										  target: self,
										  selector: #selector(self.timerAction),
										  userInfo: nil,
										  repeats: true)
	}
	
	@objc func timerAction()
	{
		if let imgView = self.view.viewWithTag(self.currentIndex) as? UIImageView
		{
			imgView.removeFromSuperview()
		}
		
		self.currentIndex -= 1
		
		if (self.currentIndex < 10)
		{
			self.timer?.invalidate()
			self.timer = nil
			
			self.dismiss(animated: true)
		}
	}
    


}
