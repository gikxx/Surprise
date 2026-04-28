import UIKit

// MARK: - AddEditPersonViewController

final class AddEditPersonViewController: UIViewController {

    // MARK: - Callbacks

    var onSave: ((
        _ name: String,
        _ day: Int,
        _ month: Int,
        _ year: Int?,
        _ eventType: PersonEventType,
        _ notes: String?
    ) -> Void)?

    // MARK: - State

    private let editingPerson: Person?
    private var selectedEventType: PersonEventType = .birthday
    private var includeYear: Bool = false

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
        l.font = .miama(size: 26)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var closeButton: UIButton = {
        let b = UIButton(type: .system)
        let img = UIImage(systemName: "xmark",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        b.setImage(img, for: .normal)
        b.tintColor = UIColor.appPrimary.withAlphaComponent(0.5)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return b
    }()

    // ScrollView держит всё кроме кнопки «Сохранить»
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Имя (например, мама)"
        tf.font = .helveticaRegular(size: 16)
        tf.textColor = .appPrimary
        tf.borderStyle = .none
        tf.autocapitalizationType = .sentences
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let nameSeparator = makeSeparator()

    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .wheels
        dp.locale = Locale(identifier: "ru_RU")
        dp.overrideUserInterfaceStyle = .light   // датапикер всегда светлый, клавиатура следует системе
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    private let yearToggleStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 8
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let yearToggleLabel: UILabel = {
        let l = UILabel()
        l.text = "Указать год"
        l.font = .helveticaRegular(size: 15)
        l.textColor = .appPrimary
        return l
    }()

    private let yearToggle: UISwitch = {
        let s = UISwitch()
        s.onTintColor = UIColor(hex: "#BDD3E9")
        s.thumbTintColor = .appPrimary
        return s
    }()

    private let eventTypeLabel: UILabel = {
        let l = UILabel()
        l.text = "Тип события"
        l.font = .helveticaRegular(size: 13)
        l.textColor = UIColor.appPrimary.withAlphaComponent(0.55)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Горизонтальный скролл для чипов — чтобы не обрезались
    private let chipsScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsHorizontalScrollIndicator = false
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let chipsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.alignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private var eventTypeButtons: [UIButton] = []

    private let notesField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Заметки (необязательно)"
        tf.font = .helveticaRegular(size: 15)
        tf.textColor = .appPrimary
        tf.borderStyle = .none
        tf.autocapitalizationType = .sentences
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let notesSeparator = makeSeparator()

    // Кнопка всегда внизу — вне scrollView
    private lazy var saveButton: UIButton = UIButton.createPrimary(title: "Сохранить")

    // MARK: - Init

    init(person: Person? = nil) {
        self.editingPerson = person
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setup()
        populate()

        // Скрываем клавиатуру по тапу вне поля
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false  // чтобы не мешать другим жестам (скролл, чипы)
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Setup

    private func setup() {
        titleLabel.text = editingPerson == nil ? "Добавить" : "Редактировать"

        // Chips
        PersonEventType.allCases.forEach { type in
            let btn = makeTypeButton(type)
            eventTypeButtons.append(btn)
            chipsStack.addArrangedSubview(btn)
        }

        yearToggleStack.addArrangedSubview(yearToggleLabel)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        yearToggleStack.addArrangedSubview(spacer)
        yearToggleStack.addArrangedSubview(yearToggle)
        yearToggle.addTarget(self, action: #selector(yearToggleChanged), for: .valueChanged)

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        chipsScrollView.addSubview(chipsStack)
        NSLayoutConstraint.activate([
            chipsStack.topAnchor.constraint(equalTo: chipsScrollView.topAnchor),
            chipsStack.bottomAnchor.constraint(equalTo: chipsScrollView.bottomAnchor),
            chipsStack.leadingAnchor.constraint(equalTo: chipsScrollView.leadingAnchor),
            chipsStack.trailingAnchor.constraint(equalTo: chipsScrollView.trailingAnchor),
            chipsStack.heightAnchor.constraint(equalTo: chipsScrollView.heightAnchor),
        ])

        // Добавляем всё в view
        [handleView, titleLabel, closeButton, scrollView, saveButton].forEach { view.addSubview($0) }

        // Собираем scrollView content
        let scrollContent = UIView()
        scrollContent.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContent)

        [nameField, nameSeparator, datePicker,
         yearToggleStack, eventTypeLabel, chipsScrollView,
         notesField, notesSeparator].forEach { scrollContent.addSubview($0) }

        NSLayoutConstraint.activate([
            // Handle
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            // Title + Close
            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // ScrollView — от заголовка до saveButton
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),

            // scrollContent
            scrollContent.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContent.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContent.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContent.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollContent.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Name
            nameField.topAnchor.constraint(equalTo: scrollContent.topAnchor, constant: 16),
            nameField.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 20),
            nameField.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -20),
            nameField.heightAnchor.constraint(equalToConstant: 40),

            nameSeparator.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 2),
            nameSeparator.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            nameSeparator.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            nameSeparator.heightAnchor.constraint(equalToConstant: 1),

            // DatePicker
            datePicker.topAnchor.constraint(equalTo: nameSeparator.bottomAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor),

            // Year toggle
            yearToggleStack.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 2),
            yearToggleStack.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 20),
            yearToggleStack.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -20),
            yearToggleStack.heightAnchor.constraint(equalToConstant: 38),

            // Event type
            eventTypeLabel.topAnchor.constraint(equalTo: yearToggleStack.bottomAnchor, constant: 16),
            eventTypeLabel.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 20),

            chipsScrollView.topAnchor.constraint(equalTo: eventTypeLabel.bottomAnchor, constant: 8),
            chipsScrollView.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 20),
            chipsScrollView.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -20),
            chipsScrollView.heightAnchor.constraint(equalToConstant: 38),

            // Notes
            notesField.topAnchor.constraint(equalTo: chipsScrollView.bottomAnchor, constant: 20),
            notesField.leadingAnchor.constraint(equalTo: scrollContent.leadingAnchor, constant: 20),
            notesField.trailingAnchor.constraint(equalTo: scrollContent.trailingAnchor, constant: -20),
            notesField.heightAnchor.constraint(equalToConstant: 40),

            notesSeparator.topAnchor.constraint(equalTo: notesField.bottomAnchor, constant: 2),
            notesSeparator.leadingAnchor.constraint(equalTo: notesField.leadingAnchor),
            notesSeparator.trailingAnchor.constraint(equalTo: notesField.trailingAnchor),
            notesSeparator.heightAnchor.constraint(equalToConstant: 1),
            notesSeparator.bottomAnchor.constraint(equalTo: scrollContent.bottomAnchor, constant: -16),

            // Save button — зафиксирован снизу
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 300),
            saveButton.heightAnchor.constraint(equalToConstant: 55),
        ])

        updateTypeButtons()
    }

    private static func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.2)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeTypeButton(_ type: PersonEventType) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = "\(type.emoji) \(type.displayName)"
        config.baseForegroundColor = .appPrimary
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.helveticaRegular(size: 14)
            return a
        }

        let btn = UIButton(configuration: config)
        btn.layer.cornerRadius = 19
        btn.layer.cornerCurve = .continuous
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.appPrimary.withAlphaComponent(0.25).cgColor
        btn.clipsToBounds = true
        btn.heightAnchor.constraint(equalToConstant: 38).isActive = true
        btn.tag = PersonEventType.allCases.firstIndex(of: type) ?? 0
        btn.addTarget(self, action: #selector(eventTypeTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Populate (edit mode)

    private func populate() {
        guard let p = editingPerson else { return }
        nameField.text = p.name
        notesField.text = p.notes
        selectedEventType = p.eventType

        var components = DateComponents()
        components.day   = p.eventDay
        components.month = p.eventMonth
        components.year  = p.eventYear ?? Calendar.current.component(.year, from: Date())
        if let date = Calendar.current.date(from: components) {
            datePicker.date = date
        }

        includeYear = p.eventYear != nil
        yearToggle.isOn = includeYear
        updateTypeButtons()
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        NotificationCenter.default.post(name: .tapBarShouldShow, object: nil)
        dismiss(animated: true)
    }

    @objc private func yearToggleChanged() {
        includeYear = yearToggle.isOn
    }

    @objc private func eventTypeTapped(_ sender: UIButton) {
        selectedEventType = PersonEventType.allCases[sender.tag]
        updateTypeButtons()
        HapticFeedback.selection()
    }

    @objc private func saveTapped() {
        guard let name = nameField.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
            shake(nameField)
            return
        }
        let calendar = Calendar.current
        let day   = calendar.component(.day,   from: datePicker.date)
        let month = calendar.component(.month, from: datePicker.date)
        let year  = includeYear ? calendar.component(.year, from: datePicker.date) : nil
        let notes = notesField.text?.trimmingCharacters(in: .whitespaces)

        HapticFeedback.selection()
        onSave?(name, day, month, year, selectedEventType, notes?.isEmpty == true ? nil : notes)
        NotificationCenter.default.post(name: .tapBarShouldShow, object: nil)
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func updateTypeButtons() {
        let allTypes = PersonEventType.allCases
        for (i, btn) in eventTypeButtons.enumerated() {
            let isSelected = allTypes[i] == selectedEventType
            btn.backgroundColor = isSelected ? UIColor(hex: "#BDD3E9") : .clear
            btn.layer.borderColor = isSelected
                ? UIColor(hex: "#BDD3E9").cgColor
                : UIColor.appPrimary.withAlphaComponent(0.25).cgColor
        }
    }

    private func shake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        view.layer.add(animation, forKey: "shake")
    }
}

// MARK: - Helper (file-private duplicate avoided)
private func makeSeparator() -> UIView {
    let v = UIView()
    v.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.2)
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
}
