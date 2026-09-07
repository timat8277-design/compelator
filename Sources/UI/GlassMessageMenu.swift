//
//  GlassMessageMenu.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Стеклянное меню сообщений и панель реакций с выбором стиля обводки (блики, сплошная, скрытая).
//

import UIKit

public enum GlassOutlineStyle: Int, CaseIterable {
    case specularGlow = 0 // Блики
    case solidLine = 1    // Сплошная
    case hidden = 2       // Скрытая

    public var title: String {
        switch self {
        case .specularGlow: return "Блики (Specular Glow)"
        case .solidLine: return "Сплошная линия"
        case .hidden: return "Скрытая"
        }
    }
}

public class GlassMessageMenuOverlay: UIView {

    public var outlineStyle: GlassOutlineStyle {
        get {
            let val = UserDefaults.standard.integer(forKey: "extera_glass_outline_style")
            return GlassOutlineStyle(rawValue: val) ?? .specularGlow
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "extera_glass_outline_style")
            applyOutlineStyle()
        }
    }

    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let reactionsContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let menuContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

    private let gradientBorderLayer = CAGradientLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGlassUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupGlassUI() {
        // Фоновое размытие всего экрана
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)

        // Панель реакций (смайлы)
        reactionsContainer.translatesAutoresizingMaskIntoConstraints = false
        reactionsContainer.layer.cornerRadius = 24
        reactionsContainer.clipsToBounds = true
        addSubview(reactionsContainer)

        setupReactions()

        // Контекстное меню действий
        menuContainer.translatesAutoresizingMaskIntoConstraints = false
        menuContainer.layer.cornerRadius = 18
        menuContainer.clipsToBounds = true
        addSubview(menuContainer)

        setupMenuItems()

        NSLayoutConstraint.activate([
            reactionsContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            reactionsContainer.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            reactionsContainer.heightAnchor.constraint(equalToConstant: 48),
            reactionsContainer.widthAnchor.constraint(equalToConstant: 280),

            menuContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            menuContainer.topAnchor.constraint(equalTo: reactionsContainer.bottomAnchor, constant: 16),
            menuContainer.widthAnchor.constraint(equalToConstant: 240)
        ])

        applyOutlineStyle()
    }

    private func setupReactions() {
        let emojis = ["👍", "❤️", "🔥", "👏", "🎉", "😱"]
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        reactionsContainer.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: reactionsContainer.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: reactionsContainer.contentView.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: reactionsContainer.contentView.centerYAnchor)
        ])

        for emoji in emojis {
            let btn = UIButton(type: .system)
            btn.setTitle(emoji, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 24)
            btn.addTarget(self, action: #selector(didSelectReaction(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
    }

    private func setupMenuItems() {
        let actions = [
            ("Ответить", "arrowshape.turn.up.left"),
            ("Скопировать текст", "doc.on.doc"),
            ("Переслать", "arrowshape.turn.up.right"),
            ("ИИ Действия (extera AI)", "sparkles"),
            ("Сохранить в Галерею", "arrow.down.to.line"),
            ("Удалить", "trash")
        ]

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 1
        stack.backgroundColor = UIColor.separator.withAlphaComponent(0.2)
        menuContainer.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: menuContainer.contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: menuContainer.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: menuContainer.contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: menuContainer.contentView.bottomAnchor)
        ])

        for (title, icon) in actions {
            let btn = UIButton(type: .system)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            btn.backgroundColor = .clear
            btn.setTitle("  " + title, for: .normal)
            btn.setImage(UIImage(systemName: icon), for: .normal)
            btn.tintColor = (icon == "trash") ? .systemRed : .label
            btn.contentHorizontalAlignment = .leading
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            stack.addArrangedSubview(btn)
        }
    }

    public func applyOutlineStyle() {
        switch outlineStyle {
        case .specularGlow:
            // Блики с градиентом
            reactionsContainer.layer.borderWidth = 1.2
            reactionsContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            reactionsContainer.layer.shadowColor = UIColor.white.cgColor
            reactionsContainer.layer.shadowRadius = 8
            reactionsContainer.layer.shadowOpacity = 0.35
            reactionsContainer.layer.shadowOffset = .zero

            menuContainer.layer.borderWidth = 1.2
            menuContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            menuContainer.layer.shadowColor = UIColor.systemBlue.cgColor
            menuContainer.layer.shadowRadius = 12
            menuContainer.layer.shadowOpacity = 0.25

        case .solidLine:
            // Сплошная ровная линия
            reactionsContainer.layer.borderWidth = 1.5
            reactionsContainer.layer.borderColor = UIColor.separator.cgColor
            reactionsContainer.layer.shadowOpacity = 0

            menuContainer.layer.borderWidth = 1.5
            menuContainer.layer.borderColor = UIColor.separator.cgColor
            menuContainer.layer.shadowOpacity = 0

        case .hidden:
            // Скрытая обводка
            reactionsContainer.layer.borderWidth = 0
            reactionsContainer.layer.shadowOpacity = 0

            menuContainer.layer.borderWidth = 0
            menuContainer.layer.shadowOpacity = 0
        }
    }

    @objc private func didSelectReaction(_ btn: UIButton) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        removeFromSuperview()
    }
}
