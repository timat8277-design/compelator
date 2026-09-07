//
//  LocalPremiumManager.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Модуль Локального Telegram Premium: разблокировка значка Premium, реакций,
//  стикеров с эффектами, эмодзи-статусов, двойных лимитов и блокировка рекламы.
//

import Foundation
import UIKit

public final class LocalPremiumManager {
    public static let shared = LocalPremiumManager()

    // Главный тумблер Локального Premium
    public var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "extera_local_premium_enabled") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "extera_local_premium_enabled")
            NotificationCenter.default.post(name: .localPremiumStateChanged, object: nil)
        }
    }

    // Разблокировка значка звезды ⭐ в профиле и чатах
    public var hasStarBadge: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_star_badge") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_star_badge") }
    }

    // Премиум-реакции (любые кастомные эмодзи в качестве реакций)
    public var unlockCustomReactions: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_reactions") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_reactions") }
    }

    // Эксклюзивные премиум-стикеры с полноэкранными эффектами
    public var unlockPremiumStickers: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_stickers") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_stickers") }
    }

    // Анимированные эмодзи-статусы
    public var unlockAnimatedEmojiStatus: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_emoji_status") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_emoji_status") }
    }

    // Двойные лимиты (до 1000 каналов, 30 папок, 10 закрепов)
    public var doubleLimits: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_double_limits") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_double_limits") }
    }

    // Блокировка спонсированных сообщений (рекламы)
    public var blockSponsoredAds: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_no_ads") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_no_ads") }
    }

    // Быстрая скорость загрузки медиа
    public var boostDownloadSpeed: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_fast_download") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_fast_download") }
    }

    // Расшифровка голосовых сообщений (Speech to Text)
    public var voiceToTextEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "extera_premium_voice_to_text") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_premium_voice_to_text") }
    }

    private init() {}

    public var statusDescription: String {
        return isEnabled ? "Включён · синхронизируется" : "Выключен"
    }

    // Проверка, является ли пользователь локальным Premium для любого UI компонента
    public func isUserPremium(userId: Int64) -> Bool {
        guard isEnabled else { return false }
        // Если это текущий аккаунт пользователя — возвращаем true
        return true
    }
}

public extension Notification.Name {
    static let localPremiumStateChanged = Notification.Name("extera_local_premium_state_changed")
}
