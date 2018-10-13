//
//  PreviewView.swift
//  VisionDetection
//
//  Created by Wei Chieh Tseng on 09/06/2017.
//  Copyright © 2017 Willjay. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class PreviewView: UIView {
    
    private var maskLayer = [CAShapeLayer]()

    override func layoutSubviews() {
        super.layoutSubviews()

        self.videoLayer?.frame = self.bounds
    }

    public var _videoLayer: CALayer?

    public var videoLayer: CALayer? {
            set {
                if let oldVlue = _videoLayer {
                    oldVlue.removeFromSuperlayer()
                }

                _videoLayer = newValue

                if _videoLayer != nil {
                    self.layer.addSublayer(_videoLayer!)
                }

                self.layoutSubviews()
        }

        get {
            return _videoLayer
        }
    }

    private func addFaceLayer(in rect: CGRect) ->CAShapeLayer {
        
        let faceMask = CAShapeLayer()
        faceMask.frame = rect
        faceMask.cornerRadius = 10
        faceMask.opacity = 0.75
        faceMask.borderColor = UIColor.yellow.cgColor
        faceMask.borderWidth = 2.0
        layer.insertSublayer(faceMask, at: 1)

        maskLayer.append(faceMask)

        return faceMask
    }
    
    func drawFaceboundingBox(face : VNFaceObservation) ->CAShapeLayer {
        
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        
        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
        let facebounds = face.boundingBox.applying(translate).applying(transform)
        
        return addFaceLayer(in: facebounds)
    }
    
    func drawFaceWithLandmarks(face: VNFaceObservation) ->CAShapeLayer {
        
//        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
//
//        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
//
//        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
//        let facebounds = face.boundingBox.applying(translate).applying(transform)

        // Draw the bounding rect
        let faceLayer = drawFaceboundingBox(face: face)

        if let landmarks = face.landmarks {
            // Draw the landmarks
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.nose!, isClosed:false)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.noseCrest!, isClosed:false)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.medianLine!, isClosed:false)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.leftEye!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.leftPupil!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.leftEyebrow!, isClosed:false)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.rightEye!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.rightPupil!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.rightEye!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.rightEyebrow!, isClosed:false)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.innerLips!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.outerLips!)
            drawLandmarks(on: faceLayer, faceLandmarkRegion: landmarks.faceContour!, isClosed: false)
        }

        return faceLayer
    }

    func drawLandmarks(on targetLayer: CALayer, faceLandmarkRegion: VNFaceLandmarkRegion2D, isClosed: Bool = true) {
        let rect: CGRect = targetLayer.frame
        var points: [CGPoint] = []
        
        for i in 0..<faceLandmarkRegion.pointCount {
            let point = faceLandmarkRegion.normalizedPoints[i]
            points.append(point)
        }
        
        let landmarkLayer = drawPointsOnLayer(rect: rect, landmarkPoints: points, isClosed: isClosed)
        
        // Change scale, coordinate systems, and mirroring
        landmarkLayer.transform = CATransform3DMakeAffineTransform(
            CGAffineTransform.identity
                .scaledBy(x: rect.width, y: -rect.height)
                .translatedBy(x: 0, y: -1)
        )

        targetLayer.insertSublayer(landmarkLayer, at: 1)
    }
    
    func drawPointsOnLayer(rect:CGRect, landmarkPoints: [CGPoint], isClosed: Bool = true) -> CALayer {
        let linePath = UIBezierPath()
        linePath.move(to: landmarkPoints.first!)
        
        for point in landmarkPoints.dropFirst() {
            linePath.addLine(to: point)
        }
        
        if isClosed {
            linePath.addLine(to: landmarkPoints.first!)
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = nil
        lineLayer.opacity = 1.0
        lineLayer.strokeColor = UIColor.green.cgColor
        lineLayer.lineWidth = 0.02
        
        return lineLayer
    }
    
    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
    }
    
}
