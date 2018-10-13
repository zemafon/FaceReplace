//
//  MovieIputSourceConfiguratio.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 10/12/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class MovieIputSourceConfiguration: IputSourceConfiguration
{
    private static var videoItemStatusChangedContext = 0
    
    var player: AVPlayer
    var videoURL: URL

    lazy var concretLayer: AVPlayerLayer! = {
        return self.sourceVideoLayer as! AVPlayerLayer
    }()

    lazy var playerItemVideoOutput: AVPlayerItemVideoOutput! = {
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]

        return AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
    }()

    let sequenceRequestHandler = VNSequenceRequestHandler()
    
    init(player: AVPlayer, videoURL: URL) {
        self.player = player
        self.videoURL = videoURL
        super.init()
    }

    public override func setupSpecifiсSourceConfiguration() {
        super.setupSpecifiсSourceConfiguration()

        let layer = AVPlayerLayer(player:self.player)
        layer.videoGravity = AVLayerVideoGravity.resizeAspect
        self.sourceVideoLayer = layer;

        let asset = AVURLAsset(url: self.videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.add(self.playerItemVideoOutput)

        // see https://forums.developer.apple.com/thread/27589#128476
        playerItem.addObserver(self, forKeyPath:#keyPath(AVPlayerItem.status), options:[.initial, .old, .new], context:&MovieIputSourceConfiguration.videoItemStatusChangedContext)

        self.player.replaceCurrentItem(with: playerItem)
        
//        self.player.addPeriodicTimeObserver(forInterval:CMTime(value:1, timescale:30),
//                                            queue:self.sessionQueue,
//                                            using:{
//                                                    time in
//                                                    if playerItem.status == .readyToPlay {
//                                                        self.updateFrameSet()
//                                                        }
//                                                })
}

    internal override func runAuthtorizationStatusChallenge () {
        super.runAuthtorizationStatusChallenge()

        self.authtorizationStatus = .authorized
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        guard context == &MovieIputSourceConfiguration.videoItemStatusChangedContext else {
            super.observeValue(forKeyPath:keyPath, of:object, change:change, context:context)
            return
        }

        if let videoItem = object as! AVPlayerItem? {
            if videoItem.status == .readyToPlay {
         // see https://forums.developer.apple.com/thread/27589#128476
            }
        }
    }

    lazy var displayLink: CADisplayLink = {
        let dl = CADisplayLink(target: self, selector: #selector(updateFrameSet(_:)))
        dl.add(to: .current, forMode: RunLoop.Mode.default)
        dl.isPaused = true

        return dl
    }()

    public override func start(completion: ((Bool) -> Void)?) {
        super.start { (result) in
            if result {
                self.displayLink.isPaused = false
                self.player.play()
            }

            completion?(result)
        }
    }

    public override func stop() {
        super.stop()

        self.player.pause()

        self.displayLink.isPaused = true
    }

    @objc func updateFrameSet(_ link: CADisplayLink) {
        let nextVSync = link.timestamp + link.duration

        let videoOutput = self.playerItemVideoOutput!
        let time = videoOutput.itemTime(forHostTime: nextVSync)

        if  videoOutput.hasNewPixelBuffer(forItemTime:time),
            let buffer = videoOutput.copyPixelBuffer(forItemTime:time, itemTimeForDisplay:nil) {
            try? self.sequenceRequestHandler.perform([self.faceDetectionRequest], on:buffer)
        }
    }
}
