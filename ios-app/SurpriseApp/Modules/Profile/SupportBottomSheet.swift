import UIKit

// MARK: - SupportBottomSheet

/// Боттом-шит с формой обратной связи.
///
///     let sheet = SupportBottomSheet()
///     present(sheet, animated: true)
final class SupportBottomSheet: UIViewController {

    // MARK: - Dependencies

    private let feedbackService: FeedbackServiceProtocol

    // MARK: - Views

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.2)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "написать в поддержку"
        l.font = .helveticaRegular(size: 20)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Контейнер-рамка вокруг UITextView — имитирует стиль TextField.createWithLabel
    private let textViewContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .appWhite
        v.layer.cornerRadius = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = "ваше сообщение..."
        l.font = .helveticaRegular(size: 15)
        l.textColor = UIColor.appPrimary.withAlphaComponent(0.35)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = .helveticaRegular(size: 15)
        tv.textColor = .appPrimary
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let sendButton = UIButton.createPrimary(title: "отправить")

    // MARK: - State

    private var isSending = false

    // MARK: - Init

    init(feedbackService: FeedbackServiceProtocol = FeedbackService()) {
        self.feedbackService = feedbackService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        setupUI()
        setupKeyboard()
        textView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    // MARK: - Sheet setup

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                let custom = UISheetPresentationController.Detent.custom(
                    identifier: .init("support_form")
                ) { _ in 380 }
                sheet.detents = [custom, .large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = 24
        }
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FAF7F4")

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)

        [handleView, titleLabel, textViewContainer, sendButton].forEach {
            view.addSubview($0)
        }

        textViewContainer.addSubview(textView)
        textViewContainer.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            textViewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textViewContainer.heightAnchor.constraint(equalToConstant: 160),

            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor, constant: 14),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor, constant: -14),

            placeholderLabel.topAnchor.constraint(equalTo: textViewContainer.topAnchor, constant: 14),
            placeholderLabel.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 16),

            sendButton.topAnchor.constraint(equalTo: textViewContainer.bottomAnchor, constant: 20),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 220),
            sendButton.heightAnchor.constraint(equalToConstant: 55),
        ])
    }

    // MARK: - Keyboard

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardHeight = max(0, view.window?.bounds.height ?? 0 - keyboardFrame.minY ?? 0)
        UIView.animate(withDuration: duration) {
            self.additionalSafeAreaInsets.bottom = keyboardHeight
        }
    }

    // MARK: - Actions

    @objc private func didTapSend() {
        let message = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty, !isSending else { return }

        isSending = true
        sendButton.isEnabled = false
        textView.resignFirstResponder()

        Task {
            do {
                try await feedbackService.submitFeedback(message: message, email: nil)
                await MainActor.run {
                    self.dismiss(animated: true)
                    Toast.show("Сообщение отправлено!")
                }
            } catch {
                await MainActor.run {
                    self.isSending = false
                    self.sendButton.isEnabled = true
                    Toast.show("Не удалось отправить. Попробуй снова.")
                }
            }
        }
    }
}

// MARK: - UITextViewDelegate

extension SupportBottomSheet: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
