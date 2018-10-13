//
//  CameraIputSourceConfiguration.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 10/12/18.
//  Copyright © 2018 Willjay. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CameraIputSourceConfiguration: IputSourceConfiguration
{
    private var devicePosition: AVCaptureDevice.Position = .back

    private let session = AVCaptureSession()
    private var isSessionRunning = false

    private var videoDeviceInput: AVCaptureDeviceInput!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")

    public var videoOrientation: AVCaptureVideoOrientation! {
        get {
            let statusBarOrientation = UIApplication.shared.statusBarOrientation

            if statusBarOrientation.videoOrientation != nil && statusBarOrientation != .unknown {
                return statusBarOrientation.videoOrientation
            }

            return .portrait
        }
    }

    private var concretLayer: AVCaptureVideoPreviewLayer? {
        get {
            return self.sourceVideoLayer as! AVCaptureVideoPreviewLayer?
        }
    }

    public override func start(completion: ((Bool) -> Void)? = nil) {
        super.start { [unowned self] result in
            if result {
                self.resume()

                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            }

            DispatchQueue.main.async {
                if result {
                    self.updateSourceVideoLayerSettings()
                }

                completion?(result)
            }
        }
    }

    public override func stop() {
        super.stop()

        self.sleep()

        self.session.stopRunning()
        self.isSessionRunning = self.session.isRunning
        self.removeObservers()
    }

    override func sleep() {
        if !self.isSleeped {
            super.sleep()

            self.sessionQueue.suspend()
        }
    }

    override func resume() {
        if self.isSleeped {
            super.resume()

            self.sessionQueue.resume()
        }
    }

    override func runAuthtorizationStatusChallenge() {
        super.runAuthtorizationStatusChallenge()

        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            self.authtorizationStatus = .authorized
            break

        case .notDetermined:
            self.sleep()

            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [unowned self] granted in
                if !granted {
                    self.authtorizationStatus = .notAuthorized
                }
                self.resume()
            })

        default:
            self.authtorizationStatus = .notAuthorized
        }
    }

    override func setupSpecifiсSourceConfiguration() {
        super.setupSpecifiсSourceConfiguration()

        self.sourceVideoLayer = AVCaptureVideoPreviewLayer(session:self.session)

        self.sessionQueue.async {
            self.configureSession()
        }
    }

    public override func updateSourceVideoLayerSettings() {
        if let videoPreviewLayerConnection = self.concretLayer!.connection {
            let deviceOrientation = UIDevice.current.orientation

            guard let newVideoOrientation = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
            }

            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    private func configureSession() {

        if self.authtorizationStatus != .authorized {
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .high

        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }

            else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }

            else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }

            else {
                print("Could not add video device input to the session")
                self.authtorizationStatus = .configurationFailed
                session.commitConfiguration()
                return
            }

        }
        catch {
            print("Could not create video device input: \(error)")
            self.authtorizationStatus = .configurationFailed
            session.commitConfiguration()
            return
        }

        // add output
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]


        if session.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            session.addOutput(videoDataOutput)
        } else {
            print("Could not add metadata output to the session")
            self.authtorizationStatus = .configurationFailed
        }

        session.commitConfiguration()
    }

    private func availableSessionPresets() -> [String] {
        let allSessionPresets = [AVCaptureSession.Preset.photo,
                                 AVCaptureSession.Preset.low,
                                 AVCaptureSession.Preset.medium,
                                 AVCaptureSession.Preset.high,
                                 AVCaptureSession.Preset.cif352x288,
                                 AVCaptureSession.Preset.vga640x480,
                                 AVCaptureSession.Preset.hd1280x720,
                                 AVCaptureSession.Preset.iFrame960x540,
                                 AVCaptureSession.Preset.iFrame1280x720,
                                 AVCaptureSession.Preset.hd1920x1080,
                                 AVCaptureSession.Preset.hd4K3840x2160]

        var availableSessionPresets = [String]()
        for sessionPreset in allSessionPresets {
            if session.canSetSessionPreset(sessionPreset) {
                availableSessionPresets.append(sessionPreset.rawValue)
            }
        }

        return availableSessionPresets
    }

    func exifOrientationFromDeviceOrientation() -> UInt32 {
        enum DeviceOrientation: UInt32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation

        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = devicePosition == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = devicePosition == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
}

extension CameraIputSourceConfiguration: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation()) else { return }
        var requestOptions: [VNImageOption : Any] = [:]

        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)

        do {
            try imageRequestHandler.perform([self.faceDetectionRequest])
        }

        catch {
            print(error)
        }
    }
}

extension CameraIputSourceConfiguration {
    private func addObservers() {
        /*
         Observe the previewView's regionOfInterest to update the AVCaptureMetadataOutput's
         rectOfInterest when the user finishes resizing the region of interest.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)

        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func sessionRuntimeError(_ notification: Notification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else { return }

        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")

        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset || self.isSessionRunning {
            sessionQueue.async { [unowned self] in
                self.start()
            }
        } else {
            if !self.isSessionRunning {
                sessionQueue.async { [unowned self] in
                    self.stop()
                }
            }
        }
    }

    @objc func sessionWasInterrupted(_ notification: Notification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCamBarcode, then the user can let AVCamBarcode resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
        }
    }

    @objc func sessionInterruptionEnded(_ notification: Notification) {
        print("Capture session interruption ended")
    }
}
