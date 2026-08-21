//
//  CamCapture.swift
//  CameraTest
//
//  Created by ISHIGO Yusuke on 2025/05/15.
//

import UIKit
import AVFoundation
import CoreMedia

protocol CamCaptureDelegate: AnyObject
{
	func camCaptureDidCapture(image: UIImage)
	func camCaptureDidRecord(url: URL)
}

enum CamCaptureCaptureMode
{
	case photo
	case video
}

class CamCapture: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate
{
	private var captureSession: AVCaptureSession!
	
	private var dataOutput: AVCaptureOutput!
	
	private var videoConnection: AVCaptureConnection!
	
	private weak var previewLayerRef: AVCaptureVideoPreviewLayer?

	var delegate: CamCaptureDelegate?
	
	private var isCapturing = false
	private(set) var isRecording = false
	
	private var _captureMode: CamCaptureCaptureMode = .photo
	var captureMode: CamCaptureCaptureMode {
		get {
			return _captureMode
		}
		set {
			_captureMode = newValue
			self.setupAVCapture(isFront: _isFront)
		}
	}
	
	private var _isFront = false
	var isFront : Bool {
		get {
			return _isFront
		}
		set {
			_isFront = newValue
			self.setupAVCapture(isFront: _isFront)
		}
	}
	
	private var _zoomFactor: CGFloat = 1.0
	var zoomFactor: CGFloat {
		get {
			return _zoomFactor
		}
		set {
			_zoomFactor = newValue
			self.setZoomFactor(factor: _zoomFactor)
		}
	}
	
	var flashMode: AVCaptureDevice.FlashMode = .off

	var _exposureAutoMode = false
	var exposureAutoMode: Bool {
		get {
			return _exposureAutoMode
		}
		set {
			_exposureAutoMode = newValue
			
			if (_exposureAutoMode)
			{
				self.resetExposureToAuto()
			}
		}
	}
	
	override init()
	{
		super.init()
		
		self.setupAVCapture(isFront: self.isFront)
	}
	
	deinit
	{
		self.disposeAVCapture()
	}
	
	/* -----------------------------------------------------
	* 初期化処理
	------------------------------------------------------ */
	private func setupAVCapture(isFront: Bool)
	{
		self.disposeAVCapture()
		
		self.captureSession = AVCaptureSession()
		
		if let captureSession = self.captureSession
		{
			captureSession.beginConfiguration()
			
			captureSession.sessionPreset = .photo
			
			guard let input = self.captureDeviceInput(isFront: self.isFront) else
			{
				print("Failed: Get capture device input.")
				return
			}
			
			if (captureSession.canAddInput(input))
			{
				captureSession.addInput(input)
			}
			
			// 写真の場合
			if (self.captureMode == .photo)
			{
				self.dataOutput = self.capturePhotoOutput()
			}
			// 動画の場合
			else if (self.captureMode == .video)
			{
				self.dataOutput = self.captureVideoOutput()
			}

			guard let dataOutput = self.dataOutput else
			{
				print("Failed: Get capture device output.")
				return
			}
			
			if (captureSession.canAddOutput(dataOutput))
			{
				captureSession.addOutput(dataOutput)
			}
			
			self.videoConnection = dataOutput.connection(with: .video)
			self.applyVideoRotationAngle(to: self.videoConnection)
			
			captureSession.commitConfiguration()
			
			DispatchQueue.global(qos: .userInitiated).async
			{
				self.captureSession.startRunning()
			}
		}
	}
	
	/* -----------------------------------------------------
	* 画面の向きに合わせて回転を更新
	------------------------------------------------------ */
	func updateOrientation()
	{
		self.applyVideoRotationAngle(to: self.videoConnection)
		self.applyVideoRotationAngle(to: self.previewLayerRef?.connection)
	}
	
	/* -----------------------------------------------------
	* 終了処理
	------------------------------------------------------ */
	private func disposeAVCapture()
	{
		self.isCapturing = false
		
		guard let captureSession = self.captureSession else { return }
		
		if (!self.captureSession.isRunning)
		{
			return
		}
		
		if (self.isRecording)
		{
			self.stopRecording()
		}

		DispatchQueue.global(qos: .userInitiated).sync {
			captureSession.stopRunning()
		}
		
		captureSession.beginConfiguration()
		
		for output in captureSession.outputs
		{
			captureSession.removeOutput(output)
		}
		
		for input in captureSession.inputs
		{
			captureSession.removeInput(input)
		}
		
		captureSession.commitConfiguration()
		
		self.dataOutput = nil
	}
	
	/* -----------------------------------------------------
	* プレビューレイヤーの取得
	------------------------------------------------------ */
	func previewLayer(frame:CGRect) -> AVCaptureVideoPreviewLayer?
	{
		guard let captureSession = self.captureSession else { return nil }
		
		let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		self.applyVideoRotationAngle(to: previewLayer.connection)
		
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.frame = frame
		
		// フロントカメラの場合は反転する
		if (self.isFront)
		{
			previewLayer.setAffineTransform(CGAffineTransform(scaleX: -1.0, y: 1.0))
		}
		
		self.previewLayerRef = previewLayer
		
		return previewLayer
	}
	
	/* -----------------------------------------------------
	* 静止画の撮影
	------------------------------------------------------ */
	func capture()
	{
		guard let dataOutput = self.dataOutput as? AVCapturePhotoOutput else { return }

		if (self.isCapturing) { return }
		if (self.captureMode != .photo) { return }

		self.isCapturing = true
		self.applyVideoRotationAngle(to: self.videoConnection)
		
		let settings = AVCapturePhotoSettings()
		
		if (dataOutput.supportedFlashModes.contains(.on))
		{
			settings.flashMode = self.flashMode
		}
		
		dataOutput.capturePhoto(with: settings, delegate: self)
	}
	
	/* -----------------------------------------------------
	* 動画の録画開始
	------------------------------------------------------ */
	func startRecording(url:URL)
	{
		guard let dataOutput = self.dataOutput as? AVCaptureMovieFileOutput else { return }
		if (self.isRecording) { return }
		if (self.captureMode != .video) { return }
		
		self.applyVideoRotationAngle(to: self.videoConnection)
		dataOutput.startRecording(to: url, recordingDelegate: self)
		
		self.isRecording = true
	}
	
	/* -----------------------------------------------------
	* 動画の録画終了
	------------------------------------------------------ */
	func stopRecording()
	{
		guard let dataOutput = self.dataOutput as? AVCaptureMovieFileOutput else { return }
		if (!self.isRecording) { return }
		if (self.captureMode != .video) { return }

		dataOutput.stopRecording()
	}
	
	/* -----------------------------------------------------
	* 露出の変更
	------------------------------------------------------ */
	func setExposure(iso:Float, duration:CMTime)
	{
		guard let deviceInput = self.captureSession.inputs.first as? AVCaptureDeviceInput else { return }
		
		let device = deviceInput.device
		
		let minISO = device.activeFormat.minISO
		let maxISO = device.activeFormat.maxISO
		
		do {
			try device.lockForConfiguration()
			device.setExposureModeCustom(duration: duration, iso: max(minISO, min(iso, maxISO)))
			device.unlockForConfiguration()
		}
		catch {
			print("Failed: setExposure")
		}
	}
	
	/* -----------------------------------------------------
	* ズームの変更
	------------------------------------------------------ */
	func setZoomFactor(factor: CGFloat)
	{
		guard let deviceInput = self.captureSession.inputs.first as? AVCaptureDeviceInput else { return }
		
		let device = deviceInput.device
		
		do {
			try device.lockForConfiguration()
			
			let zoom = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
			device.videoZoomFactor = zoom
			
			device.unlockForConfiguration()
		}
		catch {
			print("Failed: setZoomFactor")
		}
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?)
	{
		guard let imageData = photo.fileDataRepresentation() else
		{
			self.isCapturing = false
			return
		}
		
		if let img = UIImage(data: imageData)
		{
			self.delegate?.camCaptureDidCapture(image: img)
		}
		
		self.isCapturing = false
	}
	
	func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?)
	{
		self.delegate?.camCaptureDidRecord(url: outputFileURL)
		
		self.isRecording = false
	}

	
	private func resetExposureToAuto()
	{
		guard let deviceInput = self.captureSession.inputs.first as? AVCaptureDeviceInput else { return }
		
		let device = deviceInput.device
		
		do {
			try device.lockForConfiguration()
			device.exposureMode = .continuousAutoExposure
			device.unlockForConfiguration()
		}
		catch {
			print("Failed: resetExposureToAuto")
		}
	}
	
	private func captureDeviceInput(isFront: Bool) -> AVCaptureDeviceInput?
	{
		let position = self.isFront ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back

		guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
														  for: .video,
														  position: position) else
		{
			print("ERROR: Missing camera.")
			return nil
		}
		
		let deviceInut = try? AVCaptureDeviceInput(device: captureDevice)
		return deviceInut
	}
	
	private func currentVideoRotationAngle() -> CGFloat
	{
		let orientation: UIInterfaceOrientation
		if let scene = UIApplication.shared.connectedScenes
			.compactMap({ $0 as? UIWindowScene })
			.first
		{
			orientation = scene.interfaceOrientation
		}
		else
		{
			orientation = .landscapeRight
		}
		
		switch orientation
		{
		case .portrait:
			return 90
		case .portraitUpsideDown:
			return 270
		case .landscapeRight:
			return 0
		case .landscapeLeft:
			return 180
		default:
			return 0
		}
	}
	
	private func applyVideoRotationAngle(to connection: AVCaptureConnection?)
	{
		guard let connection = connection else { return }
		
		let angle = self.currentVideoRotationAngle()
		if connection.isVideoRotationAngleSupported(angle)
		{
			connection.videoRotationAngle = angle
		}
	}
	
	private func capturePhotoOutput() -> AVCapturePhotoOutput?
	{
		let dataOutput = AVCapturePhotoOutput()
		
		return dataOutput
	}
	
	private func captureVideoOutput() -> AVCaptureMovieFileOutput?
	{
		let videoDataOutput = AVCaptureMovieFileOutput()
		
		return videoDataOutput
	}
}
