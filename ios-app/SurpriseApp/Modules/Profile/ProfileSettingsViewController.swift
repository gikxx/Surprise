import UIKit
import PhotosUI

final class ProfileSettingsViewController: UIViewController {
    var onBack: (() -> Void)?
    var onSave: ((String?, String?, String?) -> Void)?
    var onAvatarSelected: ((String) -> Void)?
    var onDeleteAccount: (() -> Void)?

    private let initialUser: User
    private var currentAvatarUrl: String?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let backButton = UIButton(type: .system)
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Настройки профиля"
        label.font = .miama(size: 32)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let blueStarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "blue_star"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let pinkStarImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "pink_star"))
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let photoAvatarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .appWhite
        view.layer.cornerRadius = 60
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.appSecondary.cgColor
        return view
    }()

    private let photoAvatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let photoAvatarPlaceholderIcon: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 30, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "camera", withConfiguration: cfg))
        iv.tintColor = .appSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let leftCheckmarkLabel: UILabel = {
        let label = UILabel()
        label.text = "✓"
        label.font = .helveticaBold(size: 42)
        label.textColor = .appSecondary
        label.isHidden = true
        return label
    }()

    private let rightCheckmarkLabel: UILabel = {
        let label = UILabel()
        label.text = "✓"
        label.font = .helveticaBold(size: 42)
        label.textColor = .appSecondary
        label.isHidden = true
        return label
    }()

    private let photoCheckmarkLabel: UILabel = {
        let label = UILabel()
        label.text = "✓"
        label.font = .helveticaBold(size: 42)
        label.textColor = .appSecondary
        label.isHidden = true
        return label
    }()
    
    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Личная информация"
        label.font = .helveticaBold(size: 24)
        label.textColor = .appPrimary
        label.textAlignment = .center
        return label
    }()
    
    private let sectionSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Не забудьте сохранить данные"
        label.font = .helveticaRegular(size: 11)
        label.textColor = .appPrimary.withAlphaComponent(0.65)
        label.textAlignment = .center
        return label
    }()
    
    // Поля ввода
    private let nameField = UITextField.createWithLabel(title: "имя")
    private let emailField = UITextField.createWithLabel(title: "почта")
    private let phoneField = UITextField.createWithLabel(title: "телефон")
    
    private let saveButton = UIButton.createPrimary(title: "сохранить")

    private let deleteAccountButton: RoundedButton = {
        let btn = RoundedButton(type: .system)
        btn.setTitle("удалить аккаунт", for: .normal)
        btn.backgroundColor = .appSecondary
        btn.setTitleColor(.appTextSecondary, for: .normal)
        btn.titleLabel?.font = .helveticaRegular(size: 21)
        return btn
    }()
    
    init(user: User) {
        self.initialUser = user
        self.currentAvatarUrl = user.avatarUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        setupKeyboardHandling()
        prefillFields()
        setupAvatarSelection()
        highlightSelectedAvatar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupUI() {
        backButton.setImage(UIImage(named: "back_icon"), for: .normal)
        backButton.tintColor = .appSecondary
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        [titleLabel, blueStarImageView, pinkStarImageView, photoAvatarContainer,
         sectionTitleLabel, sectionSubtitleLabel,
         nameField, emailField, phoneField, saveButton, deleteAccountButton,
         leftCheckmarkLabel, rightCheckmarkLabel, photoCheckmarkLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        [photoAvatarImageView, photoAvatarPlaceholderIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            photoAvatarContainer.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 58),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            blueStarImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            blueStarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -60),
            blueStarImageView.widthAnchor.constraint(equalToConstant: 120),
            blueStarImageView.heightAnchor.constraint(equalToConstant: 120),
            
            pinkStarImageView.centerYAnchor.constraint(equalTo: blueStarImageView.centerYAnchor),
            pinkStarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 60),
            pinkStarImageView.widthAnchor.constraint(equalToConstant: 120),
            pinkStarImageView.heightAnchor.constraint(equalToConstant: 120),
            
            leftCheckmarkLabel.topAnchor.constraint(equalTo: blueStarImageView.topAnchor, constant: -12),
            leftCheckmarkLabel.trailingAnchor.constraint(equalTo: blueStarImageView.trailingAnchor, constant: 12),

            rightCheckmarkLabel.topAnchor.constraint(equalTo: pinkStarImageView.topAnchor, constant: -12),
            rightCheckmarkLabel.trailingAnchor.constraint(equalTo: pinkStarImageView.trailingAnchor, constant: 12),

            // Третий вариант — фото из галереи. Кладём по центру под звёздами.
            photoAvatarContainer.topAnchor.constraint(equalTo: blueStarImageView.bottomAnchor, constant: 12),
            photoAvatarContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            photoAvatarContainer.widthAnchor.constraint(equalToConstant: 120),
            photoAvatarContainer.heightAnchor.constraint(equalToConstant: 120),

            photoAvatarImageView.topAnchor.constraint(equalTo: photoAvatarContainer.topAnchor),
            photoAvatarImageView.leadingAnchor.constraint(equalTo: photoAvatarContainer.leadingAnchor),
            photoAvatarImageView.trailingAnchor.constraint(equalTo: photoAvatarContainer.trailingAnchor),
            photoAvatarImageView.bottomAnchor.constraint(equalTo: photoAvatarContainer.bottomAnchor),

            photoAvatarPlaceholderIcon.centerXAnchor.constraint(equalTo: photoAvatarContainer.centerXAnchor),
            photoAvatarPlaceholderIcon.centerYAnchor.constraint(equalTo: photoAvatarContainer.centerYAnchor),
            photoAvatarPlaceholderIcon.widthAnchor.constraint(equalToConstant: 36),
            photoAvatarPlaceholderIcon.heightAnchor.constraint(equalToConstant: 36),

            photoCheckmarkLabel.topAnchor.constraint(equalTo: photoAvatarContainer.topAnchor, constant: -12),
            photoCheckmarkLabel.trailingAnchor.constraint(equalTo: photoAvatarContainer.trailingAnchor, constant: 12),

            sectionTitleLabel.topAnchor.constraint(equalTo: photoAvatarContainer.bottomAnchor, constant: 24),
            sectionTitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            sectionSubtitleLabel.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 6),
            sectionSubtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nameField.topAnchor.constraint(equalTo: sectionSubtitleLabel.bottomAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 52),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -52),
            
            emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 20),
            emailField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            emailField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            
            phoneField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20),
            phoneField.leadingAnchor.constraint(equalTo: nameField.leadingAnchor),
            phoneField.trailingAnchor.constraint(equalTo: nameField.trailingAnchor),
            
            saveButton.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: 28),
            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 220),
            saveButton.heightAnchor.constraint(equalToConstant: 55),

            deleteAccountButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            deleteAccountButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            deleteAccountButton.widthAnchor.constraint(equalToConstant: 220),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 55),
            deleteAccountButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -120),
        ])

        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(didTapDeleteAccount), for: .touchUpInside)
    }
    
    private func prefillFields() {
        setText(initialUser.name, in: nameField)
        setText(initialUser.email ?? "", in: emailField)
        setText(initialUser.phone ?? "", in: phoneField)
    }
    
    private func setupAvatarSelection() {
        let tapBlue = UITapGestureRecognizer(target: self, action: #selector(didTapBlueAvatar))
        blueStarImageView.addGestureRecognizer(tapBlue)

        let tapPink = UITapGestureRecognizer(target: self, action: #selector(didTapPinkAvatar))
        pinkStarImageView.addGestureRecognizer(tapPink)

        let tapPhoto = UITapGestureRecognizer(target: self, action: #selector(didTapPhotoAvatar))
        photoAvatarContainer.addGestureRecognizer(tapPhoto)

        refreshPhotoPreview()
    }

    @objc private func didTapBlueAvatar() {
        HapticFeedback.selection()
        let avatarUrl = "builtin://blue_star"
        onAvatarSelected?(avatarUrl)
        currentAvatarUrl = avatarUrl
        highlightSelectedAvatar()
    }

    @objc private func didTapPinkAvatar() {
        HapticFeedback.selection()
        let avatarUrl = "builtin://pink_star"
        onAvatarSelected?(avatarUrl)
        currentAvatarUrl = avatarUrl
        highlightSelectedAvatar()
    }

    @objc private func didTapPhotoAvatar() {
        HapticFeedback.tap()

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Сфотографироваться", style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }

        sheet.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })

        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = photoAvatarContainer
            popover.sourceRect = photoAvatarContainer.bounds
        }

        present(sheet, animated: true)
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func highlightSelectedAvatar() {
        let isBlueSelected = (currentAvatarUrl == "builtin://blue_star")
        let isPinkSelected = (currentAvatarUrl == "builtin://pink_star")
        let isCustomPhotoSelected = (currentAvatarUrl == AvatarLocalStorage.urlString)

        leftCheckmarkLabel.isHidden = !isBlueSelected
        rightCheckmarkLabel.isHidden = !isPinkSelected
        photoCheckmarkLabel.isHidden = !isCustomPhotoSelected
    }

    /// Обновляет превью загруженного локально фото в третьем кружке.
    /// Если фото нет — показываем placeholder с плюсом.
    private func refreshPhotoPreview() {
        if let image = AvatarLocalStorage.loadImage() {
            photoAvatarImageView.image = image
            photoAvatarPlaceholderIcon.isHidden = true
        } else {
            photoAvatarImageView.image = nil
            photoAvatarPlaceholderIcon.isHidden = false
        }
    }
    
    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let fields = inputTextFields()
        for (index, field) in fields.enumerated() {
            field.delegate = self
            field.returnKeyType = (index == fields.count - 1) ? .done : .next
        }
    }
    
    private func inputTextFields() -> [UITextField] {
        [nameField, emailField, phoneField].compactMap { container in
            container.subviews.first(where: { $0 is UITextField }) as? UITextField
        }
    }
    
    private func text(in container: UIView) -> String {
        let field = container.subviews.first(where: { $0 is UITextField }) as? UITextField
        return field?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func setText(_ value: String, in container: UIView) {
        let field = container.subviews.first(where: { $0 is UITextField }) as? UITextField
        field?.text = value
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func didTapBack() {
        onBack?()
    }
    
    @objc private func didTapSave() {
        let name = text(in: nameField)
        let email = text(in: emailField)
        let phone = text(in: phoneField)
        
        guard !name.isEmpty else {
            showAlert(message: "Имя не может быть пустым")
            return
        }
        
        onSave?(name, email.isEmpty ? nil : email, phone.isEmpty ? nil : phone)
    }

    @objc private func didTapDeleteAccount() {
        HapticFeedback.selection()
        let alertView = ConfirmationAlertView(
            title: "Внимание!",
            message: "Все ваши данные будут удалены безвозвратно. Это действие нельзя отменить.",
            confirmTitle: "удалить аккаунт"
        )
        alertView.onConfirm = { [weak self] in
            self?.onDeleteAccount?()
        }
        alertView.show(in: view)
    }

    func updateUser(_ user: User) {
        currentAvatarUrl = user.avatarUrl
        highlightSelectedAvatar()
        setText(user.name, in: nameField)
        setText(user.email ?? "", in: emailField)
        setText(user.phone ?? "", in: phoneField)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

extension ProfileSettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = inputTextFields()
        guard let currentIndex = fields.firstIndex(of: textField) else {
            textField.resignFirstResponder()
            return true
        }
        let nextIndex = currentIndex + 1
        if nextIndex < fields.count {
            fields[nextIndex].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate (камера)

extension ProfileSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        let image = info[.originalImage] as? UIImage

        guard let image else { return }

        handlePickedImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate (галерея)

extension ProfileSettingsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self)
        else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self,
                  let image = object as? UIImage,
                  error == nil
            else { return }

            DispatchQueue.main.async {
                self.handlePickedImage(image)
            }
        }
    }
}

// MARK: - Shared image handling

private extension ProfileSettingsViewController {

    /// Единая точка сохранения фото — используется и камерой, и галереей.
    func handlePickedImage(_ image: UIImage) {
        guard let savedUrl = AvatarLocalStorage.save(image: image) else {
            HapticFeedback.warning()
            showAlert(message: "Не удалось сохранить фото. Попробуйте ещё раз.")
            return
        }
        HapticFeedback.success()
        currentAvatarUrl = savedUrl
        refreshPhotoPreview()
        highlightSelectedAvatar()
        onAvatarSelected?(savedUrl)
    }
}
