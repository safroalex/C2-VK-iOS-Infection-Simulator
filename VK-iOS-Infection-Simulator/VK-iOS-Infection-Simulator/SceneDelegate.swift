//
//  SceneDelegate.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 22.03.2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let parametersViewController = ParametersInputViewController()
        let navigationController = UINavigationController(rootViewController: parametersViewController)
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}



