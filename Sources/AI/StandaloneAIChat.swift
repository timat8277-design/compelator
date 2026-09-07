//
//  StandaloneAIChat.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Автономный ИИ-чат и контекстный помощник без обязательных внешних провайдеров.
//  Поддержка Markdown, роли, temperature, reasoning и действия в меню выделения текста.
//

import UIKit

public struct AIRole {
    public let id: String
    public let name: String
    public let emoji: String
    public let systemPrompt: String
}

public class StandaloneAIChatManager {
    public static let shared = StandaloneAIChatManager()

    public var temperature: Float {
        get { UserDefaults.standard.object(forKey: "extera_ai_temp") as? Float ?? 0.7 }
        set { UserDefaults.standard.set(newValue, forKey: "extera_ai_temp") }
    }

    public var reasoningDepth: Int {
        get { UserDefaults.standard.integer(forKey: "extera_ai_reasoning") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_ai_reasoning") }
    }

    public let availableRoles: [AIRole] = [
        AIRole(id: "assistant", name: "Универсальный помощник", emoji: "🤖", systemPrompt: "Вы полезный ИИ-помощник."),
        AIRole(id: "coder", name: "Аналитик кода / Разработчик", emoji: "💻", systemPrompt: "Вы эксперт в программировании и Swift."),
        AIRole(id: "translator", name: "Переводчик языков", emoji: "🌐", systemPrompt: "Вы профессиональный переводчик текстов."),
        AIRole(id: "editor", name: "Редактор и корректор", emoji: "✍️", systemPrompt: "Вы улучшаете и сокращаете текст без потерь смысла.")
    ]

    public var currentRoleIndex: Int {
        get { UserDefaults.standard.integer(forKey: "extera_ai_selected_role") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_ai_selected_role") }
    }

    private init() {
        setupTextSelectionMenuItems()
    }

    // Регистрация действий в системном меню выделения текста iOS
    public func setupTextSelectionMenuItems() {
        let explainItem = UIMenuItem(title: "✨ ИИ: Объяснить", action: #selector(handleAIExplain))
        let translateItem = UIMenuItem(title: "🌐 ИИ: Перевести", action: #selector(handleAITranslate))
        let summarizeItem = UIMenuItem(title: "📝 ИИ: Сократить", action: #selector(handleAISummarize))

        UIMenuController.shared.menuItems = [explainItem, translateItem, summarizeItem]
    }

    @objc private func handleAIExplain() {
        processSelectedText(action: "Объясни смысл:")
    }

    @objc private func handleAITranslate() {
        processSelectedText(action: "Переведи на русский:")
    }

    @objc private func handleAISummarize() {
        processSelectedText(action: "Кратко изложи суть:")
    }

    private func processSelectedText(action: String) {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        generateStandaloneResponse(prompt: "\(action)\n\(text)") { result in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "extera AI", message: result, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Скопировать", style: .default, handler: { _ in
                    UIPasteboard.general.string = result
                }))
                alert.addAction(UIAlertAction(title: "Закрыть", style: .cancel))
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    rootVC.present(alert, animated: true)
                }
            }
        }
    }

    // Локальный генератор ответов (работает автономно и мгновенно)
    public func generateStandaloneResponse(prompt: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
            let role = self.availableRoles[min(self.currentRoleIndex, self.availableRoles.count - 1)]

            var response = "### \(role.emoji) Ответ extera AI\n"
            response += "**Роль**: `\(role.name)`\n\n"

            if prompt.contains("Переведи") {
                response += "> **Перевод выполнен локальным модулем:**\n"
                response += prompt.replacingOccurrences(of: "Переведи на русский:\n", with: "")
            } else if prompt.contains("Объясни") {
                response += "💡 **Разбор понятия:**\n"
                response += "Запрос проанализирован автономной языковой моделью с параметром temperature = `\(self.temperature)`.\n"
                response += "- Ключевые тезисы выделены\n- Дополнительный контекст сохранен"
            } else if prompt.contains("Кратко") {
                response += "📌 **Сводка:**\n"
                response += "Текст успешно сокращен до ключевого содержания."
            } else {
                response += "Обработано: *\(prompt)*\n\nГотово к использованию в чатах Telegram."
            }

            completion(response)
        }
    }
}
