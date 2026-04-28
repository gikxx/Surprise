import UIKit

// MARK: - RangeSliderView

/// Кастомный UIControl с двумя ползунками (min и max).
///
/// Использование:
///     let slider = RangeSliderView(min: 0, max: 50_000, low: 0, high: 50_000)
///     slider.onChanged = { low, high in ... }
final class RangeSliderView: UIControl {

    // MARK: - Config

    let minValue: CGFloat
    let maxValue: CGFloat

    private(set) var lowValue: CGFloat
    private(set) var highValue: CGFloat

    /// Шаг округления (0 = непрерывно)
    var step: CGFloat = 500

    var onChanged: ((CGFloat, CGFloat) -> Void)?

    // MARK: - Appearance

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 26
    private let thumbShadowRadius: CGFloat = 4

    // MARK: - Views

    private let trackView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 2
        v.isUserInteractionEnabled = false
        return v
    }()

    private let fillView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()

    private let lowThumb = RangeSliderThumb()
    private let highThumb = RangeSliderThumb()

    // MARK: - State

    private enum ActiveThumb { case low, high, none }
    private var activeThumb: ActiveThumb = .none
    private var lastTouchX: CGFloat = 0

    // MARK: - Layout cache

    private var trackLeft: CGFloat { thumbSize / 2 }
    private var trackRight: CGFloat { bounds.width - thumbSize / 2 }
    private var trackLength: CGFloat { max(trackRight - trackLeft, 1) }

    // MARK: - Init

    init(min: CGFloat, max: CGFloat, low: CGFloat, high: CGFloat) {
        self.minValue = min
        self.maxValue = max
        self.lowValue = low
        self.highValue = high
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        trackView.backgroundColor = UIColor.appSecondary
        fillView.backgroundColor = UIColor.appPrimary

        addSubview(trackView)
        addSubview(fillView)
        addSubview(lowThumb)
        addSubview(highThumb)
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: thumbSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let midY = bounds.midY

        // Track
        trackView.frame = CGRect(
            x: trackLeft,
            y: midY - trackHeight / 2,
            width: trackLength,
            height: trackHeight
        )

        updateThumbFrames()
    }

    private func updateThumbFrames() {
        let lowX = xPosition(for: lowValue)
        let highX = xPosition(for: highValue)
        let midY = bounds.midY

        lowThumb.frame = CGRect(
            x: lowX - thumbSize / 2,
            y: midY - thumbSize / 2,
            width: thumbSize,
            height: thumbSize
        )

        highThumb.frame = CGRect(
            x: highX - thumbSize / 2,
            y: midY - thumbSize / 2,
            width: thumbSize,
            height: thumbSize
        )

        // Fill between thumbs
        fillView.frame = CGRect(
            x: lowX,
            y: bounds.midY - trackHeight / 2,
            width: max(highX - lowX, 0),
            height: trackHeight
        )

        // Z-order: active thumb on top
        bringSubviewToFront(lowThumb)
        bringSubviewToFront(highThumb)
    }

    // MARK: - Touch Tracking

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let x = touch.location(in: self).x
        lastTouchX = x

        let lowX = xPosition(for: lowValue)
        let highX = xPosition(for: highValue)

        let distLow = abs(x - lowX)
        let distHigh = abs(x - highX)

        // Если очень близко к обоим — выбираем тот, куда тянем
        if distLow <= thumbSize && distHigh <= thumbSize {
            // Предпочитаем тот, что ближе
            activeThumb = distLow <= distHigh ? .low : .high
        } else if distLow <= thumbSize {
            activeThumb = .low
        } else if distHigh <= thumbSize {
            activeThumb = .high
        } else {
            activeThumb = .none
            return false
        }

        UIView.animate(withDuration: 0.12) {
            self.thumb(for: self.activeThumb)?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }

        return true
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard activeThumb != .none else { return false }

        let x = touch.location(in: self).x
        var raw = value(for: x)
        raw = raw.clamped(to: minValue...maxValue)

        if step > 0 {
            raw = (raw / step).rounded() * step
        }

        switch activeThumb {
        case .low:
            lowValue = min(raw, highValue)
        case .high:
            highValue = max(raw, lowValue)
        case .none:
            break
        }

        updateThumbFrames()
        onChanged?(lowValue, highValue)
        sendActions(for: .valueChanged)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        UIView.animate(withDuration: 0.12) {
            self.thumb(for: self.activeThumb)?.transform = .identity
        }
        activeThumb = .none
    }

    override func cancelTracking(with event: UIEvent?) {
        activeThumb = .none
    }

    // MARK: - Helpers

    private func xPosition(for value: CGFloat) -> CGFloat {
        let fraction = (value - minValue) / (maxValue - minValue)
        return trackLeft + fraction * trackLength
    }

    private func value(for x: CGFloat) -> CGFloat {
        let fraction = (x - trackLeft) / trackLength
        return minValue + fraction * (maxValue - minValue)
    }

    private func thumb(for active: ActiveThumb) -> UIView? {
        switch active {
        case .low: return lowThumb
        case .high: return highThumb
        case .none: return nil
        }
    }

    // MARK: - Public

    func setValues(low: CGFloat, high: CGFloat, animated: Bool = false) {
        lowValue = low.clamped(to: minValue...maxValue)
        highValue = high.clamped(to: minValue...maxValue)
        if animated {
            UIView.animate(withDuration: 0.25) { self.updateThumbFrames() }
        } else {
            updateThumbFrames()
        }
    }
}

// MARK: - RangeSliderThumb

private final class RangeSliderThumb: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .appWhite
        layer.cornerRadius = 0  // будет задан в layoutSubviews
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        isUserInteractionEnabled = false

        // Внутренняя точка
        let dot = UIView()
        dot.backgroundColor = .appPrimary
        dot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dot)
        NSLayoutConstraint.activate([
            dot.centerXAnchor.constraint(equalTo: centerXAnchor),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),
        ])
        dot.layer.cornerRadius = 5
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}

// MARK: - Comparable clamp helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
