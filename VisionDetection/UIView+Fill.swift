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
}
