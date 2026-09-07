//
//  ChimeraNFTManager.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Портирование всех возможностей плагина Chimera NFT (@xarmaq):
//  1. Локальная накрутка баланса Telegram Stars (Звёзды) и токенов GRAM / TON
//  2. Выдача себе любых NFT подарков с кастомным фоном, узорами и атрибутами
//  3. Надевание (Wear) NFT подарка в шапку профиля и чатов
//  4. Collectible Username (@...), Collectible Number (+888...), NFT рейтинг
//  5. Экспорт и импорт резервных копий .profile
//

import Foundation
import UIKit

public struct NFTGiftItem: Codable {
    public let id: String
    public var title: String
    public var model: String
    public var number: Int
    public var backdropPattern: String    // узор: "Звёзды", "Короны", "Кристаллы", "Космос", "Черепа"
    public var backdropColorHex: String   // цвет фона: "#1F2338", "#D4AF37", "#152F24"
    public var rarity: String             // "Unique (1 of 1)", "Mythic", "Legendary"
    public var isWorn: Bool               // надет в шапку профиля
}

public struct ChimeraProfileData: Codable {
    public var nftUsername: String
    public var anonymousNumber: String
    public var ratingScore: Int
    public var starsBalance: Int
    public var gramBalance: Double
    public var tonBalance: Double
    public var isLocalPremiumActive: Bool
    public var activeGiftId: String?
    public var activePattern: String
    public var activeBackdrop: String
    public var lastBackupDate: Date?
    public var gifts: [NFTGiftItem]
}

public final class ChimeraNFTManager {
    public static let shared = ChimeraNFTManager()

    private let profileKey = "chimeranft_profile_data_v2"
    public private(set) var profile: ChimeraProfileData

    public var availableGifts: [NFTGiftItem] {
        get { profile.gifts }
        set { profile.gifts = newValue; saveProfile() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(ChimeraProfileData.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = ChimeraProfileData(
                nftUsername: "chimera",
                anonymousNumber: "+888 0123 4567",
                ratingScore: 9999,
                starsBalance: 777777,
                gramBalance: 1000.0,
                tonBalance: 250.0,
                isLocalPremiumActive: true,
                activeGiftId: "gift_durov_cap",
                activePattern: "Звёзды (Gold Stars)",
                activeBackdrop: "Космос / Неон (#1F2338)",
                lastBackupDate: Date(),
                gifts: [
                    NFTGiftItem(
                        id: "gift_durov_cap",
                        title: "Durov's Cap",
                        model: "cap",
                        number: 1,
                        backdropPattern: "Звёзды (Gold Stars)",
                        backdropColorHex: "#1F2338",
                        rarity: "Unique (1 of 1)",
                        isWorn: true
                    ),
                    NFTGiftItem(
                        id: "gift_pepe_king",
                        title: "King Pepe",
                        model: "pepe",
                        number: 777,
                        backdropPattern: "Короны (Emerald Crowns)",
                        backdropColorHex: "#152F24",
                        rarity: "Legendary",
                        isWorn: false
                    ),
                    NFTGiftItem(
                        id: "gift_gram_gem",
                        title: "Gram Diamond",
                        model: "gem",
                        number: 108,
                        backdropPattern: "Кристаллы (Cyan Crystals)",
                        backdropColorHex: "#1B2A4A",
                        rarity: "Mythic",
                        isWorn: false
                    ),
                    NFTGiftItem(
                        id: "gift_rocket_ton",
                        title: "TON Space Rocket",
                        model: "rocket",
                        number: 99,
                        backdropPattern: "Космос (Cosmic Stars)",
                        backdropColorHex: "#0F1A2F",
                        rarity: "Unique",
                        isWorn: false
                    )
                ]
            )
        }
    }

    // 1. Управление балансом Stars и токенов
    public func updateStarsBalance(_ count: Int) {
        profile.starsBalance = count
        saveProfile()
    }

    public func updateGramBalance(_ count: Double) {
        profile.gramBalance = count
        saveProfile()
    }

    public func updateTonBalance(_ count: Double) {
        profile.tonBalance = count
        saveProfile()
    }

    // 2. Выдача себе любого NFT подарка с любым фоном и узором
    public func mintCustomNFT(
        title: String,
        model: String,
        number: Int,
        backdropHex: String,
        pattern: String,
        rarity: String = "Unique",
        wearImmediately: Bool = true
    ) {
        let newId = "gift_\(UUID().uuidString.prefix(8).lowercased())"
        let gift = NFTGiftItem(
            id: newId,
            title: title,
            model: model,
            number: number,
            backdropPattern: pattern,
            backdropColorHex: backdropHex,
            rarity: rarity,
            isWorn: wearImmediately
        )
        if wearImmediately {
            for i in 0..<profile.gifts.count {
                profile.gifts[i].isWorn = false
            }
            profile.activeGiftId = newId
            profile.activePattern = pattern
            profile.activeBackdrop = backdropHex
        }
        profile.gifts.append(gift)
        saveProfile()
    }

    // 3. Надевание / снятие подарка (Wear)
    public func wearGift(id: String) {
        for i in 0..<profile.gifts.count {
            profile.gifts[i].isWorn = (profile.gifts[i].id == id)
            if profile.gifts[i].id == id {
                profile.activeGiftId = id
                profile.activePattern = profile.gifts[i].backdropPattern
                profile.activeBackdrop = profile.gifts[i].backdropColorHex
            }
        }
        saveProfile()
    }

    // 4. Настройка Collectible данных
    public func updateNFTUsername(_ username: String) {
        profile.nftUsername = username.replacingOccurrences(of: "@", with: "")
        saveProfile()
    }

    public func updateAnonymousNumber(_ number: String) {
        profile.anonymousNumber = number
        saveProfile()
    }

    public func updateRating(score: Int) {
        profile.ratingScore = score
        saveProfile()
    }

    public func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }

    // 5. Экспорт .profile
    public func createBackup() -> URL? {
        profile.lastBackupDate = Date()
        saveProfile()

        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupURL = docs.appendingPathComponent("chimera_\(Int(Date().timeIntervalSince1970)).profile")

        if let encoded = try? JSONEncoder().encode(profile) {
            try? encoded.write(to: backupURL)
            return backupURL
        }
        return nil
    }

    // 6. Импорт .profile
    public func restoreBackup(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ChimeraProfileData.self, from: data) else {
            return false
        }
        self.profile = decoded
        saveProfile()
        return true
    }
}
