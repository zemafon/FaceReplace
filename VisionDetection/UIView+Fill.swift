//
//  UIView+Fill.swift
//  VisionDetection
//
//  Created by Alexander Chulanov on 10/13/18.
//  Copyright © 2018 Willjay. All rights reserved.
//

import UIKit

extension UIView {
    func fillView(subView: UIView) {
        subView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor).isActive = true
        subView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        subView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        subView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    
    func topCenter(subView: UIView, width: CGFloat, height: CGFloat) {
        subView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        subView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        subView.widthAnchor.constraint(equalToConstant: width).isActive = true
        subView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    func rightCenter(subView: UIView, width: CGFloat, height: CGFloat) {
        subView.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        subView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        subView.widthAnchor.constraint(equalToConstant: width).isActive = true
        subView.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
}
