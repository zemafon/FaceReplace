//
//  VideoController.swift
//  VisionDetection
//
//  Created by Alexander Chulanov on 10/13/18.
//  Copyright © 2018 Willjay. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Vision
import RSKImageCropper

class VideoController: UIViewController {
    var videoURL: URL!
    var seekTime: TimeInterval!
    var sourceType: InputSourceType?
    var documentInteractionController: UIDocumentInteractionController!
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var recButton: UIButton!
    
    lazy var playerController: AVPlayerViewController! = {
        guard let videoURL = self.videoURL else { return nil }
        let playerController = AVPlayerViewController()
        playerController.player = AVPlayer(url: videoURL)
        return playerController
    }()
    
    private var videoSourcefaceTracker: IputSourceConfiguration? {
        didSet {
            oldValue?.stop()
        }
    }
    
    @IBAction func plussButtonTap(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        imagePicker.modalPresentationStyle = .overCurrentContext
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTap(_ sender: UIButton) {
        if let url = Bundle.main.url(forResource: "Video_001", withExtension: "mp4") {
            documentInteractionController = UIDocumentInteractionController(url: url)
            documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateInputSourceConfiguration()
    }
}

extension VideoController {
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
        if let playerView = playerController.view {
            addChild(playerController)
            willMove(toParent: self)
            playerView.translatesAutoresizingMaskIntoConstraints = false
            playerContainerView.addSubview(playerView)
            playerController.contentOverlayView?.addSubview(previewView)
            didMove(toParent: self)
            
            playerContainerView.fillView(subView: playerView)
            playerController.contentOverlayView?.fillView(subView: previewView)
        }
        if let player = self.playerController.player {
            self.videoSourcefaceTracker = MovieIputSourceConfiguration(player: player, videoURL: self.videoURL)
            
            if let movieSourcefaceTracker = videoSourcefaceTracker as? MovieIputSourceConfiguration {
                let cmSeekTime = CMTimeMakeWithSeconds(seekTime, preferredTimescale: 600)
                movieSourcefaceTracker.seekTime = cmSeekTime
            }
        }
        
        self.videoSourcefaceTracker!.setup()
        self.videoSourcefaceTracker!.trackingHandler = self.handleFaceLandmarks
        self.videoSourcefaceTracker!.start(completion: self.updateVideoLayer)
        
        self.videoSourcefaceTracker!.trackingType = .faces
    }
    
    func handleFaceLandmarks(observations: [VNFaceObservation], error: Error?) {
        self.previewView.removeMask()
        
        if let errorDescription = error?.localizedDescription {
            print(errorDescription)
        }
        else {
            
            for face in observations {
                _ = self.previewView.drawFaceImage(face: face)
            }
        }
    }
}

extension VideoController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

extension VideoController : RSKImageCropViewControllerDelegate {
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        previewView.faceImage = croppedImage
        updateInputSourceConfiguration()
        dismiss(animated: true) {
            self.previewView.layoutSubviews()
        }
    }
}
