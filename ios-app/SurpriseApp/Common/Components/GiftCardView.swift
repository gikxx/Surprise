import UIKit

final class GiftCardView: UIView {
    let imageView = UIImageView()
    let nameLabel = UILabel()
    let priceLabel = UILabel()
    let favoriteButton = UIButton(type: .system)

    var onFavoriteTapped: (() -> Void)?

    // MARK: - Image loading
    private var currentImageURL: String?
    private var imageLoadTask: URLSessionDataTask?
    private var currentImageType: ImageType = .photo

    // MARK: - Gradient
    private let gradientLayer = CAGradientLayer()

    // MARK: - Layout
    private var photoConstraints: [NSLayoutConstraint] = []
    private var transparentConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    private func setupUI() {
        backgroundColor = .appWhite
        layer.cornerRadius = 42
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.52).cgColor]
        gradientLayer.locations = [0.45, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.actions = ["hidden": NSNull()]
        imageView.layer.addSublayer(gradientLayer)

        nameLabel.font = .helveticaRegular(size: 13)
        nameLabel.textColor = .appTextMain
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        priceLabel.font = .helveticaRegular(size: 21)
        priceLabel.textColor = .appTextMain
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        favoriteButton.setImage(UIImage(named: "heart_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        favoriteButton.tintColor = .appBackground
        favoriteButton.addTarget(self, action: #selector(didTapFavorite), for: .touchUpInside)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false

        // Все subviews — дети self, не imageView
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(priceLabel)
        addSubview(favoriteButton)

        // Базовые constraints (всегда активны)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            favoriteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -21),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Photo: imageView заполняет всю карточку, текст поверх с градиентом
        photoConstraints = [
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            priceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -46),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -4),
            nameLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10),
            favoriteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
        ]

        // Transparent: imageView занимает верхние 65%, текст в нижней части
        transparentConstraints = [
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.65),
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            priceLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -4),
            nameLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
        ]

        NSLayoutConstraint.activate(photoConstraints)
    }

    func configure(with gift: Gift) {
        nameLabel.text = gift.name
        priceLabel.text = "\(Int(gift.price))₽"

        currentImageType = gift.imageType
        UIView.performWithoutAnimation {
            applyLayoutStyle(for: gift.imageType)
            layoutIfNeeded()
        }

        favoriteButton.tintColor = gift.isFavorite ? .appFavActive : .appBackground

        imageLoadTask?.cancel()
        currentImageURL = gift.imageURL
        imageView.image = UIImage(named: "gift_placeholder")

        imageLoadTask = ImageLoader.shared.loadImage(from: gift.imageURL) { [weak self] image in
            guard let self = self else { return }
            guard self.currentImageURL == gift.imageURL else { return }
            let loaded = image ?? UIImage(named: "gift_placeholder")
            self.imageView.image = loaded
            if self.currentImageType == .photo, let loaded = loaded {
                self.applyPhotoTextStyle(for: loaded)
            }
        }
    }

    /// Переключает layout-стиль (не трогает favoriteButton.tintColor).
    private func applyLayoutStyle(for type: ImageType) {
        switch type {
        case .photo:
            NSLayoutConstraint.deactivate(transparentConstraints)
            NSLayoutConstraint.activate(photoConstraints)
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            gradientLayer.isHidden = false
            nameLabel.textColor = .appWhite
            priceLabel.textColor = .appWhite
        case .transparent:
            NSLayoutConstraint.deactivate(photoConstraints)
            NSLayoutConstraint.activate(transparentConstraints)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .appWhite
            gradientLayer.isHidden = true
            nameLabel.textColor = .appTextMain
            priceLabel.textColor = .appTextMain
        }
    }

    /// Для photo-типа уточняем цвет текста по яркости нижней части загруженного фото.
    private func applyPhotoTextStyle(for image: UIImage) {
        let isLight = image.isBottomLight()
        if isLight {
            gradientLayer.isHidden = true
            nameLabel.textColor = .appTextMain
            priceLabel.textColor = .appTextMain
        } else {
            gradientLayer.isHidden = false
            nameLabel.textColor = .appWhite
            priceLabel.textColor = .appWhite
        }
    }

    func cancelImageLoad() {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        currentImageURL = nil
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let buttonPoint = convert(point, to: favoriteButton)
        if favoriteButton.bounds.insetBy(dx: -10, dy: -10).contains(buttonPoint) {
            return favoriteButton
        }
        return super.hitTest(point, with: event)
    }

    @objc private func didTapFavorite() {
        HapticFeedback.like()
        onFavoriteTapped?()
    }
}
