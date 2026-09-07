//
//  ExteraProxyManager.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Менеджер прокси: автоотключение при активном VPN, мобильной сети или Wi-Fi.
//

import Foundation
import Network

public struct ExteraProxyItem: Codable {
    public var id: String
    public var server: String
    public var port: Int
    public var secret: String?
    public var countryCode: String
    public var isPinned: Bool
    public var customName: String
}

public class ExteraProxyManager {
    public static let shared = ExteraProxyManager()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "org.extera.proxyMonitor")

    public var autoDisableOnVPN: Bool {
        get { UserDefaults.standard.bool(forKey: "extera_proxy_auto_disable_vpn") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_proxy_auto_disable_vpn") }
    }

    public var autoDisableOnCellular: Bool {
        get { UserDefaults.standard.bool(forKey: "extera_proxy_auto_disable_cellular") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_proxy_auto_disable_cellular") }
    }

    public private(set) var isProxyEnabled = true

    private init() {
        startNetworkMonitoring()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            // Проверка наличия VPN туннеля (интерфейсы utun, ppp, ipsec)
            let isScopedToVPN = path.availableInterfaces.contains { $0.name.hasPrefix("utun") || $0.name.hasPrefix("ppp") }
            let isCellular = path.isExpensive

            if self.autoDisableOnVPN && isScopedToVPN {
                self.disableProxyAutomatically(reason: "Обнаружен активный системный VPN")
            } else if self.autoDisableOnCellular && isCellular {
                self.disableProxyAutomatically(reason: "Переключение на мобильную сеть")
            } else {
                self.isProxyEnabled = true
            }
        }
        monitor.start(queue: queue)
    }

    private func disableProxyAutomatically(reason: String) {
        if isProxyEnabled {
            isProxyEnabled = false
            print("[ExteraProxy] Прокси временно отключен: \(reason)")
        }
    }
}
