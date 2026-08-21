//
//  Apps.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/20.
//

import UIKit

class Apps: NSObject
{
	public static let shared = Apps()

	var jobId = -1
	
	private override init()
	{
		super.init()
		
	}
	
	func showAlert(title: String, message: String, viewController: UIViewController)
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		viewController.present(alert, animated: true, completion: nil)
	}
	
	func showYesNoAlert(title: String, message: String, yesAction: @escaping () -> Void, viewController: UIViewController)
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in yesAction() }))
		viewController.present(alert, animated: true, completion: nil)
	}
	
}
