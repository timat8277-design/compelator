//
//  ChimeraNFTViewController.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Полноценный экран управления плагином Chimera NFT:
//  1. Накрутка Telegram Stars (Звёзды), GRAM и TON
//  2. Бесконечная локальная выдача любых NFT подарков с кастомным узором, фоном и номером
//  3. Бесконечная локальная генерация Fragment @Username и анонимных +888 номеров
//  4. Надевание (Wear) подарка в шапку профиля
//

import UIKit

public class ChimeraNFTViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let chimera = ChimeraNFTManager.shared

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chimera NFT"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(closeTapped))

        setupTableView()
        setupHeaderCard()
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemGroupedBackground

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderCard() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 160))

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1.2
        card.layer.borderColor = UIColor.systemTeal.withAlphaComponent(0.5).cgColor
        headerView.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "👑 CHIMERA NFT • ⭐ LOCAL PREMIUM"
        titleLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        titleLabel.textColor = .systemTeal
        card.addSubview(titleLabel)

        let usernameLabel = UILabel()
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.text = "@\(chimera.profile.nftUsername)"
        usernameLabel.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        usernameLabel.textColor = .label
        card.addSubview(usernameLabel)

        let numberLabel = UILabel()
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.text = "📞 \(chimera.profile.anonymousNumber)   •   🏆 \(chimera.profile.ratingScore) pts"
        numberLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        numberLabel.textColor = .secondaryLabel
        card.addSubview(numberLabel)

        let balanceLabel = UILabel()
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "⭐️ \(chimera.profile.starsBalance) Stars   💎 \(chimera.profile.gramBalance) GRAM"
        balanceLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        balanceLabel.textColor = .systemGreen
        card.addSubview(balanceLabel)

        let wornLabel = UILabel()
        wornLabel.translatesAutoresizingMaskIntoConstraints = false
        let activeGift = chimera.availableGifts.first(where: { $0.id == chimera.profile.activeGiftId })
        wornLabel.text = "🎁 Надет: \(activeGift?.title ?? "None") #\(activeGift?.number ?? 1) [Узор: \(chimera.profile.activePattern)]"
        wornLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        wornLabel.textColor = .systemOrange
        card.addSubview(wornLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            usernameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            numberLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            numberLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            wornLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 4),
            wornLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            balanceLabel.topAnchor.constraint(equalTo: wornLabel.bottomAnchor, constant: 6),
            balanceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16)
        ])

        tableView.tableHeaderView = headerView
    }

    // MARK: - TableView

    public func numberOfSections(in tableView: UITableView) -> NSInteger {
        return 4 // 0: Баланс, 1: Подарки, 2: Юзернеймы, 3: Номера
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "⭐️ НАКРУТКА БАЛАНСА (ЛОКАЛЬНО)"
        case 1: return "🎁 КОЛЛЕКЦИЯ И ВЫДАЧА NFT ПОДАРКОВ (БЕСКОНЕЧНО)"
        case 2: return "🏷️ COLLECTIBLE @USERNAME (БЕСКОНЕЧНО)"
        case 3: return "📞 АНОНИМНЫЕ +888 НОМЕРА (БЕСКОНЕЧНО)"
        default: return nil
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Stars, GRAM, TON
        case 1: return 1 + chimera.availableGifts.count
        case 2: return 2 // Добавить + активный
        case 3: return 2 // Добавить + активный
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.accessoryType = .disclosureIndicator

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "⭐️ Telegram Stars (Звёзды)"
                cell.detailTextLabel?.text = "\(chimera.profile.starsBalance) ⭐️ (Нажмите для накрутки)"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "💎 Баланс GRAM"
                cell.detailTextLabel?.text = "\(chimera.profile.gramBalance) GRAM (Нажмите для накрутки)"
            } else {
                cell.textLabel?.text = "🔷 Баланс TON"
                cell.detailTextLabel?.text = "\(chimera.profile.tonBalance) TON (Нажмите для накрутки)"
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "➕ Выдать себе новый NFT подарок"
                cell.detailTextLabel?.text = "Выбор модели, узора, фона и номера"
                cell.textLabel?.textColor = .systemTeal
            } else {
                let gift = chimera.availableGifts[indexPath.row - 1]
                let isWorn = (gift.id == chimera.profile.activeGiftId)
                cell.textLabel?.text = "\(isWorn ? "👑" : "🎁") \(gift.title) #\(gift.number) \(isWorn ? "[НАДЕТ]" : "")"
                cell.detailTextLabel?.text = "Узор: \(gift.backdropPattern) | Фон: \(gift.backdropColorHex)"
                if isWorn { cell.textLabel?.textColor = .systemOrange }
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "➕ Добавить новый NFT Username"
                cell.detailTextLabel?.text = "Создать коллекционный юзернейм"
                cell.textLabel?.textColor = .systemTeal
            } else {
                cell.textLabel?.text = "@\(chimera.profile.nftUsername) ✅ [АКТИВЕН]"
                cell.detailTextLabel?.text = "Нажмите, чтобы изменить"
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "➕ Добавить новый +888 номер"
                cell.detailTextLabel?.text = "Создать анонимный номер"
                cell.textLabel?.textColor = .systemTeal
            } else {
                cell.textLabel?.text = "\(chimera.profile.anonymousNumber) ✅ [АКТИВЕН]"
                cell.detailTextLabel?.text = "Нажмите, чтобы изменить"
            }
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            // Накрутка Stars
            if indexPath.row == 0 {
                let alert = UIAlertController(title: "⭐️ Накрутка Stars", message: "Введите любое количество звёзд:", preferredStyle: .alert)
                alert.addTextField { $0.keyboardType = .numberPad; $0.text = "\(self.chimera.profile.starsBalance)" }
                alert.addAction(UIAlertAction(title: "+100,000 ⭐️", style: .default, handler: { _ in
                    self.chimera.updateStarsBalance(self.chimera.profile.starsBalance + 100000)
                    self.setupHeaderCard()
                    self.tableView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "+1,000,000 ⭐️", style: .default, handler: { _ in
                    self.chimera.updateStarsBalance(self.chimera.profile.starsBalance + 1000000)
                    self.setupHeaderCard()
                    self.tableView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                    if let text = alert.textFields?.first?.text, let val = Int(text) {
                        self.chimera.updateStarsBalance(val)
                        self.setupHeaderCard()
                        self.tableView.reloadData()
                    }
                }))
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
                present(alert, animated: true)
            } else if indexPath.row == 1 {
                let alert = UIAlertController(title: "💎 Баланс GRAM", message: "Введите баланс GRAM:", preferredStyle: .alert)
                alert.addTextField { $0.keyboardType = .decimalPad; $0.text = "\(self.chimera.profile.gramBalance)" }
                alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                    if let text = alert.textFields?.first?.text, let val = Double(text) {
                        self.chimera.updateGramBalance(val)
                        self.setupHeaderCard()
                        self.tableView.reloadData()
                    }
                }))
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
                present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "🔷 Баланс TON", message: "Введите баланс TON:", preferredStyle: .alert)
                alert.addTextField { $0.keyboardType = .decimalPad; $0.text = "\(self.chimera.profile.tonBalance)" }
                alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                    if let text = alert.textFields?.first?.text, let val = Double(text) {
                        self.chimera.updateTonBalance(val)
                        self.setupHeaderCard()
                        self.tableView.reloadData()
                    }
                }))
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
                present(alert, animated: true)
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                // Выдать себе новый NFT подарок с выбором фона и узора
                let alert = UIAlertController(title: "🎁 Выдача NFT Подарка", message: "Настройте модель, номер, узор и фон:", preferredStyle: .alert)
                alert.addTextField { $0.placeholder = "Модель (Durov's Cap, King Pepe)"; $0.text = "Cyber Skull" }
                alert.addTextField { $0.placeholder = "Номер (#1, #777)"; $0.text = "777"; $0.keyboardType = .numberPad }
                alert.addTextField { $0.placeholder = "Узор (Звёзды, Короны, Кристаллы)"; $0.text = "Золотые Звёзды (Gold Stars)" }
                alert.addTextField { $0.placeholder = "Фон (Неон, Золото, Изумруд)"; $0.text = "Неон Киберпанк (#1F2338)" }

                alert.addAction(UIAlertAction(title: "Выдать и Надеть", style: .default, handler: { _ in
                    let title = alert.textFields?[0].text ?? "NFT"
                    let num = Int(alert.textFields?[1].text ?? "1") ?? 1
                    let pat = alert.textFields?[2].text ?? "Звёзды"
                    let bg = alert.textFields?[3].text ?? "#1F2338"

                    self.chimera.mintCustomNFT(title: title, model: "custom", number: num, backdropHex: bg, pattern: pat, rarity: "Unique", wearImmediately: true)
                    self.setupHeaderCard()
                    self.tableView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
                present(alert, animated: true)
            } else {
                let gift = chimera.availableGifts[indexPath.row - 1]
                chimera.wearGift(id: gift.id)
                setupHeaderCard()
                tableView.reloadData()
            }
        } else if indexPath.section == 2 {
            let alert = UIAlertController(title: "🏷️ NFT Username", message: "Введите username (без @):", preferredStyle: .alert)
            alert.addTextField { $0.text = self.chimera.profile.nftUsername }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                if let text = alert.textFields?.first?.text {
                    self.chimera.updateNFTUsername(text)
                    self.setupHeaderCard()
                    self.tableView.reloadData()
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
            present(alert, animated: true)
        } else if indexPath.section == 3 {
            let alert = UIAlertController(title: "📞 Анонимный Номер", message: "Введите номер (+888...):", preferredStyle: .alert)
            alert.addTextField { $0.text = self.chimera.profile.anonymousNumber }
            alert.addAction(UIAlertAction(title: "Сохранить", style: .default, handler: { _ in
                if let text = alert.textFields?.first?.text {
                    self.chimera.updateAnonymousNumber(text)
                    self.setupHeaderCard()
                    self.tableView.reloadData()
                }
            }))
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
}
