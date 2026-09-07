//
//  ChannelFeedController.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Лента постов каналов: все посты из каналов пользователя в единой ленте.
//

import UIKit

public struct ChannelFeedPost {
    public let id: Int64
    public let channelId: Int64
    public let channelTitle: String
    public let channelAvatarColor: UIColor
    public let date: Date
    public let text: String
    public let mediaThumbnail: UIImage?
    public let viewsCount: Int
    public let sharesCount: Int
}

public class ChannelFeedController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()

    private var posts: [ChannelFeedPost] = []
    private var isLoading = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Лента каналов"
        view.backgroundColor = .systemBackground

        setupNavigationBar()
        setupTableView()
        loadMockFeedPosts()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(didTapFilter))
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(ChannelFeedCardCell.self, forCellReuseIdentifier: "ChannelFeedCardCell")

        refreshControl.tintColor = .systemBlue
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func refreshFeed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.loadMockFeedPosts()
            self?.refreshControl.endRefreshing()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    @objc private func didTapFilter() {
        let alert = UIAlertController(title: "Фильтр ленты", message: "Настройте источники постов", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Только каналы без уведомлений", style: .default))
        alert.addAction(UIAlertAction(title: "Показать только медиа (фото/видео)", style: .default))
        alert.addAction(UIAlertAction(title: "Сбросить фильтры", style: .destructive))
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    private func loadMockFeedPosts() {
        posts = [
            ChannelFeedPost(
                id: 101,
                channelId: 1001,
                channelTitle: "exteraGram News",
                channelAvatarColor: .systemIndigo,
                date: Date().addingTimeInterval(-120),
                text: "🚀 Релиз обновления exteraGram для iOS!\n• Добавлена полноценная лента каналов\n• Кружки в 120 FPS\n• Поддержка сторонних плагинов на JavaScriptCore\n• Стеклянный интерфейс Glass M3",
                mediaThumbnail: nil,
                viewsCount: 14200,
                sharesCount: 340
            ),
            ChannelFeedPost(
                id: 102,
                channelId: 1002,
                channelTitle: "Apple Hub",
                channelAvatarColor: .systemBlue,
                date: Date().addingTimeInterval(-1800),
                text: "📱 Новые дисплеи ProMotion в iPhone поддерживают честную запись в 120 FPS без пропуска кадров благодаря новому аппаратному энкодеру.",
                mediaThumbnail: nil,
                viewsCount: 89000,
                sharesCount: 1200
            ),
            ChannelFeedPost(
                id: 103,
                channelId: 1003,
                channelTitle: "Telegram Beta Community",
                channelAvatarColor: .systemTeal,
                date: Date().addingTimeInterval(-7200),
                text: "✨ Стеклянные панели реакций и контекстные меню получили новый стиль бликов обводки (Specular Glow). Оцените в настройках оформления!",
                mediaThumbnail: nil,
                viewsCount: 45300,
                sharesCount: 890
            )
        ]
        tableView.reloadData()
    }

    // MARK: - TableView

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelFeedCardCell", for: indexPath) as? ChannelFeedCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        cell.onChannelTap = { [weak self] post in
            self?.openChannel(post.channelId, title: post.channelTitle)
        }
        return cell
    }

    private func openChannel(_ channelId: Int64, title: String) {
        let alert = UIAlertController(title: title, message: "Переход в канал ID: \(channelId)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Карточка поста в стиле Material 3 / Glass

class ChannelFeedCardCell: UITableViewCell {
    var onChannelTap: ((ChannelFeedPost) -> Void)?
    private var post: ChannelFeedPost?

    private let cardView = UIView()
    private let avatarView = UIView()
    private let avatarInitialLabel = UILabel()
    private let channelTitleButton = UIButton(type: .system)
    private let dateLabel = UILabel()
    private let postTextView = UITextView()
    private let statsLabel = UILabel()
    private let shareButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCard()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupCard() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        contentView.addSubview(cardView)

        // Аватар
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = 20
        cardView.addSubview(avatarView)

        avatarInitialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarInitialLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        avatarInitialLabel.textColor = .white
        avatarView.addSubview(avatarInitialLabel)

        // Заголовок канала
        channelTitleButton.translatesAutoresizingMaskIntoConstraints = false
        channelTitleButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        channelTitleButton.contentHorizontalAlignment = .leading
        channelTitleButton.addTarget(self, action: #selector(didTapChannel), for: .touchUpInside)
        cardView.addSubview(channelTitleButton)

        // Дата
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        cardView.addSubview(dateLabel)

        // Текст поста
        postTextView.translatesAutoresizingMaskIntoConstraints = false
        postTextView.isEditable = false
        postTextView.isScrollEnabled = false
        postTextView.backgroundColor = .clear
        postTextView.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        postTextView.textColor = .label
        cardView.addSubview(postTextView)

        // Статистика (просмотры)
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        statsLabel.textColor = .tertiaryLabel
        cardView.addSubview(statsLabel)

        // Кнопка поделиться
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.setImage(UIImage(systemName: "arrowshape.turn.up.right"), for: .normal)
        shareButton.tintColor = .secondaryLabel
        cardView.addSubview(shareButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            avatarView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            avatarInitialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            channelTitleButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            channelTitleButton.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            channelTitleButton.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -14),

            dateLabel.topAnchor.constraint(equalTo: channelTitleButton.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: channelTitleButton.leadingAnchor),

            postTextView.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 10),
            postTextView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            postTextView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            statsLabel.topAnchor.constraint(equalTo: postTextView.bottomAnchor, constant: 10),
            statsLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            statsLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            shareButton.centerYAnchor.constraint(equalTo: statsLabel.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14)
        ])
    }

    func configure(with post: ChannelFeedPost) {
        self.post = post
        avatarView.backgroundColor = post.channelAvatarColor
        avatarInitialLabel.text = String(post.channelTitle.prefix(1))
        channelTitleButton.setTitle(post.channelTitle, for: .normal)

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        dateLabel.text = formatter.localizedString(for: post.date, relativeTo: Date())

        postTextView.text = post.text
        statsLabel.text = "👁 \(post.viewsCount.formatted()) • 🔁 \(post.sharesCount)"
    }

    @objc private func didTapChannel() {
        if let post = post {
            onChannelTap?(post)
        }
    }
}
