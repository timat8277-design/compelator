//
//  ExteraSettings.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Главное меню настроек мода exteraGram для iOS.
//

import UIKit

public class ExteraSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки exteraGram"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Chimera NFT, Плагины и Лента
        case 1: return 3 // Камера (120 FPS, ультраширик, зум)
        case 2: return 3 // Оформление (Стеклянное меню, стиль обводки, M3 радиус)
        case 3: return 2 // Интерфейс (Скрыть поиск, отключить ИИ Telegram)
        case 4: return 2 // Прокси и медиа
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Ключевые функции"
        case 1: return "Камера и кружки (120 FPS)"
        case 2: return "Дизайн и стекло"
        case 3: return "Чаты и поиск"
        case 4: return "Сеть и хранилище"
        default: return nil
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ExteraSettingCell")

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "👑 Chimera NFT & Локальный Premium"
            cell.detailTextLabel?.text = LocalPremiumManager.shared.statusDescription
            cell.accessoryType = .disclosureIndicator

        case (0, 1):
            cell.textLabel?.text = "🧩 Система плагинов (ExteraHook)"
            cell.detailTextLabel?.text = "\(ExteraPluginEngine.shared.installedPlugins.count) активных"
            cell.accessoryType = .disclosureIndicator

        case (0, 2):
            cell.textLabel?.text = "📰 Лента постов всех каналов"
            cell.accessoryType = .disclosureIndicator

        case (1, 0):
            cell.textLabel?.text = "Кружки в 120 FPS (ProMotion)"
            let sw = UISwitch()
            sw.isOn = UserDefaults.standard.object(forKey: "extera_120fps_enabled") as? Bool ?? true
            sw.addTarget(self, action: #selector(toggle120FPS(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (1, 1):
            cell.textLabel?.text = "Старт записи с ультраширокоугольной"
            let sw = UISwitch()
            sw.isOn = UserDefaults.standard.bool(forKey: "extera_cam_start_ultrawide")
            sw.addTarget(self, action: #selector(toggleUltraWide(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (1, 2):
            cell.textLabel?.text = "Ползунок зума Google Camera"
            let sw = UISwitch()
            sw.isOn = true
            sw.isEnabled = false
            cell.accessoryView = sw

        case (2, 0):
            cell.textLabel?.text = "Стиль обводки стекла (Glass)"
            let style = GlassOutlineStyle(rawValue: UserDefaults.standard.integer(forKey: "extera_glass_outline_style")) ?? .specularGlow
            cell.detailTextLabel?.text = style.title
            cell.accessoryType = .disclosureIndicator

        case (2, 1):
            cell.textLabel?.text = "Скругление секций Material 3"
            cell.detailTextLabel?.text = "\(Int(Material3Theme.sectionRadius)) pt"
            cell.accessoryType = .disclosureIndicator

        case (2, 2):
            cell.textLabel?.text = "Сегментные разделители"
            let sw = UISwitch()
            sw.isOn = Material3Theme.dividerStyleSegmented
            sw.addTarget(self, action: #selector(toggleM3Dividers(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (3, 0):
            cell.textLabel?.text = "Скрыть поиск над списком чатов"
            let sw = UISwitch()
            sw.isOn = UserDefaults.standard.bool(forKey: "extera_hide_search_bar")
            sw.addTarget(self, action: #selector(toggleHideSearch(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (3, 1):
            cell.textLabel?.text = "Отключить встроенные ИИ-функции TG"
            let sw = UISwitch()
            sw.isOn = UserDefaults.standard.bool(forKey: "extera_disable_tg_ai")
            sw.addTarget(self, action: #selector(toggleDisableTGAI(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (4, 0):
            cell.textLabel?.text = "Автоотключение прокси при VPN"
            let sw = UISwitch()
            sw.isOn = ExteraProxyManager.shared.autoDisableOnVPN
            sw.addTarget(self, action: #selector(toggleProxyVPN(_:)), for: .valueChanged)
            cell.accessoryView = sw

        case (4, 1):
            cell.textLabel?.text = "Папка сохранения медиа"
            cell.detailTextLabel?.text = "Фотопленка / Extera"
            cell.accessoryType = .disclosureIndicator

        default:
            break
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 && indexPath.row == 0 {
            let chimeraVC = ChimeraNFTViewController()
            navigationController?.pushViewController(chimeraVC, animated: true)
        } else if indexPath.section == 0 && indexPath.row == 1 {
            let pluginsVC = PluginManagerViewController()
            navigationController?.pushViewController(pluginsVC, animated: true)
        } else if indexPath.section == 0 && indexPath.row == 2 {
            let feedVC = ChannelFeedController()
            navigationController?.pushViewController(feedVC, animated: true)
        } else if indexPath.section == 2 && indexPath.row == 0 {
            showGlassStylePicker()
        }
    }

    private func showGlassStylePicker() {
        let alert = UIAlertController(title: "Стиль обводки стекла", message: "Выберите визуальный эффект для меню и реакций", preferredStyle: .actionSheet)
        for style in GlassOutlineStyle.allCases {
            alert.addAction(UIAlertAction(title: style.title, style: .default, handler: { [weak self] _ in
                UserDefaults.standard.set(style.rawValue, forKey: "extera_glass_outline_style")
                self?.tableView.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func toggle120FPS(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "extera_120fps_enabled")
    }

    @objc private func toggleUltraWide(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "extera_cam_start_ultrawide")
    }

    @objc private func toggleM3Dividers(_ sender: UISwitch) {
        Material3Theme.dividerStyleSegmented = sender.isOn
    }

    @objc private func toggleHideSearch(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "extera_hide_search_bar")
    }

    @objc private func toggleDisableTGAI(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "extera_disable_tg_ai")
    }

    @objc private func toggleProxyVPN(_ sender: UISwitch) {
        ExteraProxyManager.shared.autoDisableOnVPN = sender.isOn
    }
}
