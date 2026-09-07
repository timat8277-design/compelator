//
//  Material3Styles.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Элементы и стили Material 3: скругление секций, сегментные разделители, переключатели и слайдеры.
//

import UIKit

public struct Material3Theme {
    public static var sectionRadius: CGFloat {
        get {
            let val = UserDefaults.standard.double(forKey: "extera_m3_section_radius")
            return val == 0 ? 20.0 : CGFloat(val)
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: "extera_m3_section_radius")
        }
    }

    public static var dividerStyleSegmented: Bool {
        get { UserDefaults.standard.object(forKey: "extera_m3_segmented_dividers") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "extera_m3_segmented_dividers") }
    }
}

// Карточка секции в стиле Material 3
public class M3CardView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupM3()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupM3() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = Material3Theme.sectionRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.separator.withAlphaComponent(0.15).cgColor
        clipsToBounds = true
    }

    public func reloadStyle() {
        layer.cornerRadius = Material3Theme.sectionRadius
    }
}

// Сегментный разделитель Material 3
public class M3SegmentedDivider: UIView {
    public init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        layer.cornerRadius = 0.5
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// Слайдер в стиле Material 3 с увеличенным ползунком
public class M3Slider: UISlider {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupM3Slider()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupM3Slider() {
        minimumTrackTintColor = .systemTeal
        maximumTrackTintColor = UIColor.tertiarySystemFill
        setThumbImage(generateM3Thumb(size: CGSize(width: 24, height: 24)), for: .normal)
        setThumbImage(generateM3Thumb(size: CGSize(width: 28, height: 28)), for: .highlighted)
    }

    private func generateM3Thumb(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(UIColor.systemTeal.cgColor)
            ctx.cgContext.fillEllipse(in: rect)

            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.setLineWidth(2.5)
            ctx.cgContext.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))
        }
    }
}
