//
//  CreateViewController.swift
//  nenone
//
//  Created by ISHIGO Yusuke on 2026/08/20.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa
import Alamofire

class CreateViewController: UIViewController, CamCaptureDelegate, UITableViewDelegate, UITableViewDataSource
{
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var panelImgView: UIImageView!
	@IBOutlet weak var closePanelBtn: UIButton!
	@IBOutlet weak var openPanelBtn: UIButton!
	@IBOutlet weak var finishBtn: UIButton!
	
	
	let isPanelOpened = BehaviorRelay(value: true)
	
	let camera = CamCapture()
	
	var images = [UIImage]()
	var onionImageViews = [UIImageView]()
	
	let disposeBag = DisposeBag()
	
	private var previewLayer: AVCaptureVideoPreviewLayer?
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.camera.delegate = self
		self.setupCameraPreview()
		
		self.isPanelOpened.asObservable()
			.observe(on: MainScheduler.instance)
			.skip(1)
			.subscribe(onNext: { [weak self] isOpen in
				guard let wself = self else { return }
				
				if (isOpen)
				{
					UIView.animate(withDuration: 0.7)
					{
						wself.panelImgView.transform = .identity
						wself.tableView.transform = .identity
						wself.finishBtn.transform = .identity
					}
					
					wself.openPanelBtn.isHidden = true
					wself.closePanelBtn.isHidden = false
				}
				else
				{
					UIView.animate(withDuration: 0.7)
					{
						let tx = wself.panelImgView.bounds.width - 100.0
						wself.panelImgView.transform = CGAffineTransform(translationX: tx, y: 0)
						wself.tableView.transform = CGAffineTransform(translationX: tx, y: 0)
						wself.finishBtn.transform = CGAffineTransform(translationX: tx, y: 0)
					}

					wself.openPanelBtn.isHidden = false
					wself.closePanelBtn.isHidden = true
				}
			})
			.disposed(by: self.disposeBag)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
	{
		super.viewWillTransition(to: size, with: coordinator)
		
		coordinator.animate(alongsideTransition: { _ in
			self.previewLayer?.frame = self.view.bounds
			self.camera.updateOrientation()
		})
	}
    
	private func setupCameraPreview()
	{
		guard let previewLayer = self.camera.previewLayer(
			frame: CGRect(x: 0.0,
						  y: 0.0,
						  width: self.view.frame.size.width,
						  height: self.view.frame.size.height)
		) else
		{
			return
		}
		

		self.view.layer.insertSublayer(previewLayer, at: 0)
		self.previewLayer = previewLayer
	}
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return self.images.count
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return 110 + CapturedImageCell.verticalSpacing
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "Basic-Cell", for: indexPath) as! CapturedImageCell
		cell.photoImageView.image = self.images[indexPath.row]
		
		cell.onClose = { [weak self, weak tableView, weak cell] in
			guard let self = self,
				  let tableView = tableView,
				  let cell = cell,
				  let ip = tableView.indexPath(for: cell) else { return }
			
			self.images.remove(at: ip.row)
			
			if (ip.row < self.onionImageViews.count)
			{
				let onionView = self.onionImageViews.remove(at: ip.row)
				onionView.removeFromSuperview()
			}
			
			tableView.reloadData()
		}
		
		return cell
	}
	
	@IBAction func shotBtnAction(_ sender: Any)
	{
		Apps.shared.showYesNoAlert(title: "",
								   message: "撮影しますか？",
								   yesAction: {
			self.camera.capture()
		},
								   viewController: self)
	}
	
	@IBAction func playBtnAction(_ sender: Any)
	{
		self.performSegue(withIdentifier: "toPreview", sender: self)
	}
	
	@IBAction func backBtnAction(_ sender: Any)
	{
		self.dismiss(animated: true)
	}
	
	@IBAction func closePanelBtnAction(_ sender: Any)
	{
		self.isPanelOpened.accept(false)
	}
	
	@IBAction func openPanelBtnAction(_ sender: Any)
	{
		self.isPanelOpened.accept(true)
	}
	
	@IBAction func finishBtnAction(_ sender: Any)
	{
		Apps.shared.showYesNoAlert(title: "",
								   message: "確定しますか？",
								   yesAction: { [weak self] in
			guard let self = self else { return }
			self.uploadImages()
		},
								   viewController: self)
	}
	
	private func uploadImages()
	{
		// TODO: 本番のURLに差し替える
		let url = "https://example.com/api/upload"
		
		AF.upload(multipartFormData: { multipartFormData in
			multipartFormData.append("\(Apps.shared.jobId)".data(using: .utf8)!,
									 withName: "job_id")
			
			for (index, image) in self.images.enumerated()
			{
				guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
				
				multipartFormData.append(data,
										 withName: "images[]",
										 fileName: "image_\(index).jpg",
										 mimeType: "image/jpeg")
			}
		}, to: url)
		.response { [weak self] response in
			guard let self = self else { return }
			
			if let error = response.error
			{
				Apps.shared.showAlert(title: "",
									  message: "アップロードに失敗しました\n\(error.localizedDescription)",
									  viewController: self)
				return
			}
			
			self.dismiss(animated: true)
		}
	}

	func camCaptureDidCapture(image: UIImage)
	{
		if let img = image.resize(ratio: 0.5)
		{
			self.images.insert(img, at: 0)
			self.tableView.reloadData()
			
			let onionView = UIImageView(frame: self.view.bounds)
			onionView.image = img
			onionView.contentMode = .scaleAspectFill
			onionView.clipsToBounds = true
			onionView.alpha = 0.4
			onionView.isUserInteractionEnabled = false
			onionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			
			if let frontOnion = self.onionImageViews.first
			{
				self.view.insertSubview(onionView, aboveSubview: frontOnion)
			}
			else
			{
				self.view.insertSubview(onionView, at: 0)
			}
			self.onionImageViews.insert(onionView, at: 0)
			
			if let previewLayer = self.previewLayer
			{
				self.view.layer.insertSublayer(previewLayer, at: 0)
			}
		}
	}
	
	func camCaptureDidRecord(url: URL)
	{
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if let nextViewController = segue.destination as? PreviewViewController
		{
			// Previewは後からaddした画像が手前になるので、古い→新しいの順で渡す
			nextViewController.images = self.images.reversed()
		}
	}

}
