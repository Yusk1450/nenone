//
//  SelectJobsViewController.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/19.
//

import UIKit

class SelectJobsViewController: UIViewController
{
	@IBOutlet weak var nextBtn: UIButton!

	// 職業ID
	var selectedJobId = -1

    override func viewDidLoad()
	{
		super.viewDidLoad()

		let images = ["youtuber", "programmer", "medical", "sports", "teacher", "patissier", "manga", "police", "scientist", "idol"]
		
		var index = 0
		for i in stride(from: 10, through: 100, by: 10)
		{
			if let btn = self.view.viewWithTag(i) as? UIButton, index < images.count
			{
				let name = images[index]
				btn.configuration = nil
				let offImage = UIImage(named: "job_\(name)_off")
				let onImage = UIImage(named: "job_\(name)_on")
				btn.setImage(offImage, for: .normal)
				btn.setImage(offImage, for: .highlighted)
				btn.setImage(onImage, for: .selected)
				btn.setImage(onImage, for: [.selected, .highlighted])
				btn.adjustsImageWhenHighlighted = false
				btn.addTarget(self, action: #selector(self.jobBtnAction(_:)), for: .touchUpInside)
				index += 1
			}
		}
		
	}
	
	@objc func jobBtnAction(_ sender: UIButton)
	{
		for i in stride(from: 10, through: 100, by: 10)
		{
			if let btn = self.view.viewWithTag(i) as? UIButton
			{
				btn.isSelected = (btn == sender)
			}
		}
		
		// 職業ID
		self.selectedJobId = (sender.tag as NSNumber).intValue / 10
		
		self.nextBtn.isEnabled = true
		self.nextBtn.setImage(UIImage(named: "nextbtn_on"), for: .normal)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		let apps = Apps.shared
		apps.jobId = self.selectedJobId
	}

}
