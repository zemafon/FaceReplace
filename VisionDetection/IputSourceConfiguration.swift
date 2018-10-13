//
//  IputSourceConfiguration.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 10/12/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

public enum InputSourceType: Int {
    case camera = 0
    case movie = 1
}

public typealias IputSourceTrackingHandler = ([VNFaceObservation], Error?) -> Void

public class IputSourceConfiguration : NSObject
{
    public enum FaceTrackingType: Int {
        case faces = 0
        case faceLandmarks = 1
    }

    var trackingType: FaceTrackingType = .faces {
        didSet {
            self.faceDetectionRequest = nil
        }
    }
    public var sourceVideoLayer: CALayer?

    private var _faceDetectionRequest: VNRequest?
    internal var faceDetectionRequest: VNRequest! {
        get  {
            if _faceDetectionRequest == nil {
                _faceDetectionRequest = self.makeDetectionRequest(self.trackingType)
            }

            return _faceDetectionRequest
        }

        set (newValue) {
            _faceDetectionRequest = nil
        }
    }
    public var trackingHandler: IputSourceTrackingHandler?
    internal let sessionQueue = DispatchQueue(label:"session queue", qos:DispatchQoS.userInitiated, attributes:[])

    public func setup()
    {
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        runAuthtorizationStatusChallenge()

        setupSpecifiсSourceConfiguration()
    }

    public func start(completion: ((_ result: Bool) -> Void)? = nil)
    {
        sessionQueue.async { [unowned self] in
            switch self.authtorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    completion?(true)
                }
                return

            case .notAuthorized, .notDetermined:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("AVCamBarcode doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
                    let    alertController = UIAlertController(title: "AppleFaceDetection", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                    }))

                    self.present(alertController, animated: true, completion: nil)
                }

            case .configurationFailed:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "AppleFaceDetection", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))

                    self.present(alertController, animated: true, completion: nil)
                }

            }

            completion?(false)
        }
    }

    public func stop()
    {
        
    }

    private func makeDetectionRequest(_ trackingType: FaceTrackingType) -> VNRequest! {
        switch trackingType {
        case .faces:
            return VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)
        case .faceLandmarks:
            return VNDetectFaceLandmarksRequest(completionHandler: self.handleFaces)
        }
    }

    func handleFaces(request: VNRequest, error: Error?)
    {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNFaceObservation] else {
                self.trackingHandler?([], error)

                return;
            }

            self.trackingHandler?(results, nil);
        }
    }

    internal enum SourceAuthtorizationStatus {
        case authorized
        case notDetermined
        case notAuthorized
        case configurationFailed
    }

    internal var authtorizationStatus: SourceAuthtorizationStatus = .notDetermined

    func runAuthtorizationStatusChallenge() {
    }

    func setupSpecifiсSourceConfiguration() {

    }

    var isSleeped = false

    internal func sleep() {
        self.isSleeped = true
    }

    internal func resume(){
        self.isSleeped = false
    }

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil)
    {
        UIApplication.shared.keyWindow?.rootViewController?.present(viewControllerToPresent, animated: flag, completion: completion);
    }

    public func updateSourceVideoLayerSettings () {

    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
