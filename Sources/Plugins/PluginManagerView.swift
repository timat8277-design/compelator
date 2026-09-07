//
//  PluginManagerView.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Пользовательский интерфейс управления плагинами, безопасный режим (Safe Mode) и консоль.
//

import UIKit

public class PluginManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let engine = ExteraPluginEngine.shared

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let safeModeBanner = UIView()
    private let safeModeSwitch = UISwitch()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Плагины exteraGram"
        view.backgroundColor = .systemGroupedBackground

        setupNavigationBar()
        setupViews()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        engine.loadInstalledPlugins()
        tableView.reloadData()
        updateSafeModeBanner()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddPlugin))
    }

    private func setupViews() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PluginCell.self, forCellReuseIdentifier: "PluginCell")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateSafeModeBanner() {
        safeModeSwitch.isOn = engine.isSafeModeActive
    }

    @objc private func didTapAddPlugin() {
        let alert = UIAlertController(title: "Новый плагин", message: "Введите прямую ссылку на .js скрипт или код плагина", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "https://example.com/plugin.js"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Загрузить", style: .default, handler: { [weak self] _ in
            guard let text = alert.textFields?.first?.text, let url = URL(string: text) else { return }
            self?.downloadPlugin(from: url)
        }))
        present(alert, animated: true)
    }

    private func downloadPlugin(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, let script = String(data: data, encoding: .utf8), error == nil else {
                DispatchQueue.main.async {
                    let errAlert = UIAlertController(title: "Ошибка", message: "Не удалось загрузить плагин", preferredStyle: .alert)
                    errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errAlert, animated: true)
                }
                return
            }

            let pluginName = url.deletingPathExtension().lastPathComponent
            DispatchQueue.main.async {
                self?.engine.installPlugin(name: pluginName, script: script)
                self?.tableView.reloadData()
            }
        }.resume()
    }

    // MARK: - TableView Data Source

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Safe Mode
        case 1: return max(1, engine.installedPlugins.count) // Плагины
        case 2: return 1 // Логи консоли
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Безопасность"
        case 1: return "Установленные плагины"
        case 2: return "Отладка и логи"
        default: return nil
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SafeModeCell")
            cell.textLabel?.text = "Безопасный режим (Safe Mode)"
            cell.detailTextLabel?.text = "Отключает выполнение всех плагинов при сбоях"
            let toggle = UISwitch()
            toggle.isOn = engine.isSafeModeActive
            toggle.addTarget(self, action: #selector(toggleSafeMode(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            return cell

        case 1:
            if engine.installedPlugins.isEmpty {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "EmptyCell")
                cell.textLabel?.text = "Нет установленных плагинов"
                cell.textLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .none
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PluginCell", for: indexPath) as? PluginCell else {
                return UITableViewCell()
            }
            let plugin = engine.installedPlugins[indexPath.row]
            cell.configure(with: plugin) { [weak self] isEnabled in
                self?.engine.togglePlugin(id: plugin.id, enabled: isEnabled)
            }
            return cell

        case 2:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "LogsCell")
            cell.textLabel?.text = "Открыть консоль логов (\(engine.debugLogs.count))"
            cell.accessoryType = .disclosureIndicator
            return cell

        default:
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 2 {
            let logsVC = PluginLogsViewController()
            navigationController?.pushViewController(logsVC, animated: true)
        }
    }

    @objc private func toggleSafeMode(_ sender: UISwitch) {
        engine.isSafeModeActive = sender.isOn
        engine.reloadAll()
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
}

class PluginCell: UITableViewCell {
    private var onToggle: ((Bool) -> Void)?

    private let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        accessoryView = toggle
        toggle.addTarget(self, action: #selector(didToggle), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with plugin: PluginMetadata, onToggle: @escaping (Bool) -> Void) {
        textLabel?.text = "\(plugin.name) (v\(plugin.version))"
        detailTextLabel?.text = "\(plugin.description) • Автор: \(plugin.author)"
        toggle.isOn = plugin.isEnabled
        self.onToggle = onToggle
    }

    @objc private func didToggle() {
        onToggle?(toggle.isOn)
    }
}

class PluginLogsViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Логи плагинов"
        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.text = ExteraPluginEngine.shared.debugLogs.joined(separator: "\n")

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
