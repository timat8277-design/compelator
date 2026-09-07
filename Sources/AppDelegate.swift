//
//  AppDelegate.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Инициализация ядра плагинов exteraGram
        ExteraPluginEngine.shared.setupContext()
        ExteraPluginEngine.shared.loadInstalledPlugins()

        // Инициализация Локального Premium и Chimera NFT
        _ = LocalPremiumManager.shared
        _ = ChimeraNFTManager.shared

        // Инициализация ИИ контекстного меню
        StandaloneAIChatManager.shared.setupTextSelectionMenuItems()

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainTabBar = UITabBarController()

        let feedNav = UINavigationController(rootViewController: ChannelFeedController())
        feedNav.tabBarItem = UITabBarItem(title: "Лента", image: UIImage(systemName: "newspaper.fill"), tag: 0)

        let cameraVC = ExteraCamera120FPSController()
        cameraVC.tabBarItem = UITabBarItem(title: "Кружки 120 FPS", image: UIImage(systemName: "camera.circle.fill"), tag: 1)

        let settingsNav = UINavigationController(rootViewController: ExteraSettingsViewController())
        settingsNav.tabBarItem = UITabBarItem(title: "Настройки", image: UIImage(systemName: "gearshape.fill"), tag: 2)

        mainTabBar.viewControllers = [feedNav, cameraVC, settingsNav]
        mainTabBar.tabBar.tintColor = .systemTeal

        window?.rootViewController = mainTabBar
        window?.makeKeyAndVisible()

        return true
    }
}
