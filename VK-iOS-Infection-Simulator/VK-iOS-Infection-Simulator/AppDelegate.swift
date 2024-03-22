//
//  AppDelegate.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 22.03.2024.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = ParametersInputViewController() // Ваш корневой ViewController
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        return true
    }
}


