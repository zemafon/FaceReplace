//
//  AppDelegate.swift
//  VisionDetection
//
//  Created by Ilya Dzhantemirov on 09/06/2017.
//  Copyright © 2017 Home. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

}

internal extension AppDelegate {
     enum AppRunnerDeviceType {
        case simulator
        case device
    }

 class var deviceType: AppRunnerDeviceType! {
    var type: AppRunnerDeviceType
        #if targetEnvironment(simulator)
        type = AppRunnerDeviceType.simulator
        #else
        type = AppRunnerDeviceType.device
        #endif

        return type
    }
}
