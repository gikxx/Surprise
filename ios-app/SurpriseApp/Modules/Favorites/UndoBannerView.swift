import UIKit

// MARK: - UndoBannerView

final class UndoBannerView: UIView {

    // MARK: - Callbacks

    var onUndo: (() -> Void)?
    var onExpired: (() -> Void)?

    // MARK: - Constants

    private let totalSeconds = 5
    private let bannerHeight: CGFloat = 52
    private let horizontalMargin: CGFloat = 16

    // MARK: - State

    private var secondsLeft: Int = 5
    private var countdownTimer: Timer?
    private var bottomConstraint: NSLayoutConstraint?

    // MARK: - Views

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.text = "Удалено из избранного"
        l.font = .helveticaRegular(size: 15)
        l.textColor = .appPrimary
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let undoButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Отмена", for: .normal)
        b.setTitleColor(.appPrimary, for: .normal)
        b.titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 15)
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let countdownLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 13)
        l.textColor = UIColor.appPrimary.withAlphaComponent(0.5)
        l.textAlignment = .right
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = UIColor(hex: "#BDD3E9")
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(messageLabel)
        addSubview(undoButton)
        addSubview(countdownLabel)

        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            undoButton.leadingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8),
            undoButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            countdownLabel.leadingAnchor.constraint(equalTo: undoButton.trailingAnchor, constant: 4),
            countdownLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            countdownLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            countdownLabel.widthAnchor.constraint(equalToConstant: 18),
        ])

        updateCountdown()
    }

    // MARK: - Public API

    func show(in parentView: UIView, bottomOffset: CGFloat) {
        parentView.addSubview(self)

        let bottom = bottomConstraint ?? {
            let c = bottomAnchor.constraint(
                equalTo: parentView.safeAreaLayoutGuide.bottomAnchor,
                constant: bannerHeight + 20
            )
            c.isActive = true
            bottomConstraint = c
            return c
        }()

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: horizontalMargin),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -horizontalMargin),
            heightAnchor.constraint(equalToConstant: bannerHeight),
        ])

        parentView.layoutIfNeeded()

        bottom.constant = -(bottomOffset - 8)
        UIView.animate(withDuration: 0.4, delay: 0,
                       usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5) {
            parentView.layoutIfNeeded()
        }

        startTimer()
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        stopTimer()
        guard let superview, let bottom = bottomConstraint else {
            removeFromSuperview()
            completion?()
            return
        }
        if animated {
            bottom.constant = bannerHeight + 20
            UIView.animate(withDuration: 0.3, animations: {
                superview.layoutIfNeeded()
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
                completion?()
            })
        } else {
            removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        secondsLeft = totalSeconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        secondsLeft -= 1
        updateCountdown()
        if secondsLeft <= 0 {
            stopTimer()
            onExpired?()
            dismiss()
        }
    }

    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdown() {
        countdownLabel.text = "\(secondsLeft)"
    }

    // MARK: - Actions

    @objc private func undoTapped() {
        HapticFeedback.selection()
        onUndo?()
        dismiss()
    }
}
