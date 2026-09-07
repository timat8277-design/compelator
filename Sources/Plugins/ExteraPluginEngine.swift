//
//  ExteraPluginEngine.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Движок плагинов и хуков на базе JavaScriptCore (аналог Chaquopy/exteraHook).
//

import Foundation
import JavaScriptCore
import UIKit

@objc protocol ExteraBridgeProtocol: JSExport {
    func log(_ message: String)
    func notify(_ title: String, _ body: String)
    func copyToClipboard(_ text: String)
    func sendMessage(_ chatId: Int64, _ text: String)
    func registerCommand(_ command: String, _ callback: JSValue)
    func registerHook(_ eventName: String, _ callback: JSValue)
    func getSetting(_ key: String) -> String?
    func setSetting(_ key: String, _ value: String)
}

@objc class ExteraBridge: NSObject, ExteraBridgeProtocol {
    weak var engine: ExteraPluginEngine?

    init(engine: ExteraPluginEngine) {
        self.engine = engine
    }

    func log(_ message: String) {
        print("[ExteraPlugin] \(message)")
        engine?.appendLog(message)
    }

    func notify(_ title: String, _ body: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }

    func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    func sendMessage(_ chatId: Int64, _ text: String) {
        engine?.delegate?.exteraSendMessage(chatId: chatId, text: text)
    }

    func registerCommand(_ command: String, _ callback: JSValue) {
        engine?.commands[command.lowercased()] = callback
        print("[ExteraPlugin] Зарегистрирована команда: .\(command)")
    }

    func registerHook(_ eventName: String, _ callback: JSValue) {
        if engine?.hooks[eventName] == nil {
            engine?.hooks[eventName] = []
        }
        engine?.hooks[eventName]?.append(callback)
        print("[ExteraPlugin] Зарегистрирован хук события: \(eventName)")
    }

    func getSetting(_ key: String) -> String? {
        return UserDefaults.standard.string(forKey: "extera_plugin_\(key)")
    }

    func setSetting(_ key: String, _ value: String) {
        UserDefaults.standard.set(value, forKey: "extera_plugin_\(key)")
    }
}

public protocol ExteraPluginDelegate: AnyObject {
    func exteraSendMessage(chatId: Int64, text: String)
    func exteraDeleteMessage(chatId: Int64, messageId: Int32)
}

public struct PluginMetadata {
    public let id: String
    public let name: String
    public let version: String
    public let author: String
    public let description: String
    public var isEnabled: Bool
    public let script: String
}

public final class ExteraPluginEngine {
    public static let shared = ExteraPluginEngine()

    public weak var delegate: ExteraPluginDelegate?

    private var jsContext: JSContext?
    internal var commands: [String: JSValue] = [:]
    internal var hooks: [String: [JSValue]] = [:]
    public private(set) var installedPlugins: [PluginMetadata] = []
    public private(set) var debugLogs: [String] = []

    // Safe mode защита от сбоев
    public var isSafeModeActive: Bool {
        get { UserDefaults.standard.bool(forKey: "extera_safe_mode") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_safe_mode") }
    }

    private let pluginsDirectory: URL

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.pluginsDirectory = documentsPath.appendingPathComponent("ExteraPlugins", isDirectory: true)
        createPluginsDirectoryIfNeeded()
        setupContext()
        loadInstalledPlugins()
    }

    private func createPluginsDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
    }

    public func setupContext() {
        commands.removeAll()
        hooks.removeAll()

        guard !isSafeModeActive else {
            appendLog("⚠️ Включен SAFE MODE: Плагины временно отключены.")
            return
        }

        let context = JSContext()
        context?.exceptionHandler = { [weak self] _, exception in
            let error = exception?.toString() ?? "Неизвестная ошибка JS"
            self?.appendLog("❌ Ошибка в плагине: \(error)")
        }

        let bridge = ExteraBridge(engine: self)
        context?.setObject(bridge, forKeyedSubscript: "extera" as NSString)
        context?.setObject(bridge, forKeyedSubscript: "telegram" as NSString)

        self.jsContext = context
        appendLog("✅ JavaScriptCore движок инициализирован")
    }

    public func executeHook(eventName: String, arguments: [Any]) -> Any? {
        guard !isSafeModeActive, let registeredHooks = hooks[eventName] else { return nil }

        for hook in registeredHooks {
            let result = hook.call(withArguments: arguments)
            if let boolVal = result?.toBool(), !boolVal {
                // Если хук вернул false — прерываем цепочку
                return false
            }
        }
        return true
    }

    public func handleCommand(text: String, chatId: Int64) -> Bool {
        guard text.hasPrefix(".") else { return false }
        let parts = text.dropFirst().components(separatedBy: " ")
        guard let commandName = parts.first?.lowercased() else { return false }

        if let handler = commands[commandName] {
            let args = Array(parts.dropFirst())
            handler.call(withArguments: [args, chatId])
            return true
        }
        return false
    }

    public func loadInstalledPlugins() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: pluginsDirectory, includingPropertiesForKeys: nil) else { return }

        installedPlugins.removeAll()

        for fileUrl in files where fileUrl.pathExtension == "js" {
            guard let scriptContent = try? String(contentsOf: fileUrl, encoding: .utf8) else { continue }
            let plugin = parsePluginMetadata(script: scriptContent, fileUrl: fileUrl)
            installedPlugins.append(plugin)

            if plugin.isEnabled && !isSafeModeActive {
                runPlugin(plugin)
            }
        }
    }

    private func parsePluginMetadata(script: String, fileUrl: URL) -> PluginMetadata {
        let id = fileUrl.deletingPathExtension().lastPathComponent
        var name = id
        var version = "1.0.0"
        var author = "Community"
        var description = "Плагин exteraGram"

        for line in script.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("@name") { name = trimmed.replacingOccurrences(of: "//@name", with: "").trimmingCharacters(in: .whitespaces) }
            if trimmed.contains("@version") { version = trimmed.replacingOccurrences(of: "//@version", with: "").trimmingCharacters(in: .whitespaces) }
            if trimmed.contains("@author") { author = trimmed.replacingOccurrences(of: "//@author", with: "").trimmingCharacters(in: .whitespaces) }
            if trimmed.contains("@description") { description = trimmed.replacingOccurrences(of: "//@description", with: "").trimmingCharacters(in: .whitespaces) }
        }

        let isEnabled = UserDefaults.standard.object(forKey: "plugin_enabled_\(id)") as? Bool ?? true
        return PluginMetadata(id: id, name: name, version: version, author: author, description: description, isEnabled: isEnabled, script: script)
    }

    public func runPlugin(_ plugin: PluginMetadata) {
        guard let context = jsContext else { return }
        context.evaluateScript(plugin.script)
        appendLog("🚀 Запущен плагин: \(plugin.name) (v\(plugin.version))")
    }

    public func installPlugin(name: String, script: String) {
        let fileUrl = pluginsDirectory.appendingPathComponent("\(name).js")
        try? script.write(to: fileUrl, atomically: true, encoding: .utf8)
        reloadAll()
    }

    public func togglePlugin(id: String, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "plugin_enabled_\(id)")
        reloadAll()
    }

    public func reloadAll() {
        setupContext()
        loadInstalledPlugins()
    }

    internal func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        debugLogs.append("[\(timestamp)] \(message)")
        if debugLogs.count > 100 { debugLogs.removeFirst() }
    }
}
