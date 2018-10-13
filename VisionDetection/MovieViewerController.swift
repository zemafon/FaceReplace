//
//  MovieViewerController.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 10/13/18.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders
import CoreMedia
import AVFoundation

internal class MovieViewerController: UIViewController {

    lazy var canvas: MetalView! = {
        return self.view as! MetalView
    }()

    let moviewSourceTracker: MovieIputSourceConfiguration! = {

        var source: MovieIputSourceConfiguration? = nil

        guard let videoURL = Bundle.main.url(forResource: "Video_001", withExtension:"mp4") else {
            print("MovieIputSourceConfiguration initialisation fail")
            return source
        }

        let player = AVPlayer(url:videoURL)

        source = MovieIputSourceConfiguration(player:player, videoURL
            :videoURL)
//        source!.handleBufferFrame = self.fetchFrameBuffer

        return source!
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.moviewSourceTracker.setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.stop()

        self.viewWillDisappear(animated)
    }

    func run () {
        moviewSourceTracker.start { (result) in
            if result {

            }
        }
    }

    func stop () {
        moviewSourceTracker.stop()
    }

    func fetchFrameBuffer (pixelBuffer: CVPixelBuffer, time: CMTime) {
        self.canvas.pixelBuffer = pixelBuffer
        self.canvas.inputTime = time.seconds
    }
}

extension MTLTexture {

    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }

    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }

    
}

