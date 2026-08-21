//
//  UIImageEx.swift
//  XmasPB
//
//  Created by Yusk1450 on 2016/12/15.
//  Copyright © 2016年 Yusk. All rights reserved.
//

import UIKit

extension UIImage
{
	/* -----------------------------------------------------
	* 指定した倍率でリサイズした画像を返す
	------------------------------------------------------ */
	func resize(ratio:CGFloat) -> UIImage?
	{
		var resImg:UIImage?
		
		let sz = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
		UIGraphicsBeginImageContext(sz)
		self.draw(in: CGRect(x: 0.0, y: 0.0, width: sz.width, height: sz.height))
		resImg = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndPDFContext()
		
		return resImg
	}
}
