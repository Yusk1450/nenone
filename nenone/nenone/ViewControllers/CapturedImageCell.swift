//
//  CapturedImageCell.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/20.
//

import UIKit

class CapturedImageCell: UITableViewCell
{
	@IBOutlet weak var photoImageView: UIImageView!
	@IBOutlet weak var closeButton: UIButton!
	
	// 閉じるボタンが押されたときに呼ばれる
	var onClose: (() -> Void)?
	
	// セル間の余白（上下に半分ずつ入る）
	static let verticalSpacing: CGFloat = 10
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		self.photoImageView.frame = self.contentView.bounds.insetBy(dx: 0, dy: CapturedImageCell.verticalSpacing / 2)
		self.contentView.bringSubviewToFront(self.closeButton)
	}
	
	@IBAction func closeButtonTapped(_ sender: Any)
	{
		self.onClose?()
	}
}
