//
//  ViewController.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 09/06/2017.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import RSKImageCropper

class ViewController: UIViewController {
    @IBOutlet weak var sourceTypeSegmentedControl : UISegmentedControl!
    @IBOutlet weak var trackingTypeSegmentedControl : UISegmentedControl!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var plussButton: UIButton!

    var sourceType: InputSourceType?
    var documentInteractionController: UIDocumentInteractionController!

    private var videoSourcefaceTracker: IputSourceConfiguration? {
        didSet {
            oldValue?.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if AppDelegate.deviceType == .simulator {
            self.sourceTypeSegmentedControl.setEnabled(false, forSegmentAt:0)
            self.sourceTypeSegmentedControl.selectedSegmentIndex = 1
        }

        self.updateInputSourceConfiguration()
    }

    func updateVideoLayer(result: Bool) {
        self.previewView.videoLayer = self.videoSourcefaceTracker?.sourceVideoLayer        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoSourcefaceTracker!.stop()

        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.previewView.layoutSubviews()

       self.videoSourcefaceTracker?.updateSourceVideoLayerSettings()
    }

    private func updateInputSourceConfiguration ()
    {
        if let newSourceType = InputSourceType(rawValue: sourceTypeSegmentedControl.selectedSegmentIndex) {

            if newSourceType != self.sourceType {

                self.sourceType = newSourceType

                switch newSourceType {
                case .camera:
                    self.videoSourcefaceTracker = CameraIputSourceConfiguration()
                    break;
                case .movie:
                    self.videoSourcefaceTracker = MovieIputSourceConfiguration()
                    break;
                }

                self.videoSourcefaceTracker!.setup()
                self.videoSourcefaceTracker!.trackingHandler = self.handleFaceLandmarks
                self.videoSourcefaceTracker!.start(completion: self.updateVideoLayer)
            }
        }
        
        if let trackingType = IputSourceConfiguration.FaceTrackingType(rawValue: trackingTypeSegmentedControl.selectedSegmentIndex) {
            self.videoSourcefaceTracker!.trackingType = trackingType
        }
    }

    @IBAction func UpdateDetectionType(_ sender: UISegmentedControl) {
        updateInputSourceConfiguration()
    }
    
    @IBAction func plussButtonTap(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(imagePicker, animated: false, completion: nil)
    }
    
    @IBAction func shareButtonTap(_ sender: UIButton) {
        if let url = Bundle.main.url(forResource: "Video_001", withExtension: "mp4") {
            documentInteractionController = UIDocumentInteractionController(url: url)
            documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
        }
    }
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true) {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let cropController = RSKImageCropViewController(image: pickedImage)
                cropController.delegate = self
                self.present(cropController, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController : RSKImageCropViewControllerDelegate {
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        dismiss(animated: true) {
            
        }
    }
}

extension ViewController {
    func handleFaceLandmarks(observations: [VNFaceObservation], error: Error?) {
        self.previewView.removeMask()

        if let errorDescription = error?.localizedDescription {
            print(errorDescription)
        }
        else {

            for face in observations {
                _ = self.previewView.drawFaceWithLandmarks(face: face)
            }
        }
    }
}

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return nil
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}
