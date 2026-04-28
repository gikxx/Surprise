import UIKit

// MARK: - ConfirmationAlertView

final class ConfirmationAlertView: UIView {

    // MARK: - Callbacks
    var onConfirm: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Views

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .appBackground
        v.layer.cornerRadius = 24
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(systemName: "xmark",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        b.setImage(img, for: .normal)
        b.tintColor = UIColor.appPrimary.withAlphaComponent(0.4)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .miama(size: 28)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 15)
        l.textColor = .appPrimary
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let confirmButton: RoundedButton = {
        let b = RoundedButton(type: .system)
        b.backgroundColor = .appSecondary
        b.setTitleColor(.appTextSecondary, for: .normal)
        b.titleLabel?.font = .helveticaRegular(size: 21)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init

    init(title: String, message: String, confirmTitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        messageLabel.text = message
        confirmButton.setTitle(confirmTitle, for: .normal)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(dimView)
        addSubview(containerView)
        containerView.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),

            containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -40),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),

            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            confirmButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            confirmButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 220),
            confirmButton.heightAnchor.constraint(equalToConstant: 55),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
        ])

        closeButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped))
        dimView.addGestureRecognizer(tap)
    }


    // MARK: - Actions

    @objc private func confirm() {
        hide { [weak self] in self?.onConfirm?() }
    }

    @objc private func dismiss() {
        hide { [weak self] in self?.onDismiss?() }
    }

    @objc private func dimTapped() {
        hide { [weak self] in self?.onDismiss?() }
    }

    // MARK: - Show / Hide

    func show(in view: UIView) {
        view.addSubview(self)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }

    private func hide(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion()
        }
    }
}
