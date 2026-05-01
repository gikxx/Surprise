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

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.52).cgColor]
        gradientLayer.locations = [0.45, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

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

        addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        imageView.addSubview(nameLabel)
        imageView.addSubview(priceLabel)
        imageView.addSubview(favoriteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            favoriteButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -21),
            favoriteButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -30),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            priceLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16),
            priceLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -46),

            nameLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -4),
            nameLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 2),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: imageView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with gift: Gift) {
        nameLabel.text = gift.name
        priceLabel.text = "\(Int(gift.price))₽"
        favoriteButton.tintColor = gift.isFavorite ? .appFavActive : .appBackground

        currentImageType = gift.imageType
        applyLayoutStyle(for: gift.imageType)

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

    /// Переключает layout-стиль до загрузки картинки.
    private func applyLayoutStyle(for type: ImageType) {
        switch type {
        case .photo:
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            gradientLayer.isHidden = false
            nameLabel.textColor = .appWhite
            priceLabel.textColor = .appWhite
            favoriteButton.tintColor = .appBackground
        case .transparent:
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .appWhite
            gradientLayer.isHidden = true
            nameLabel.textColor = .appTextMain
            priceLabel.textColor = .appTextMain
            favoriteButton.tintColor = .appTextMain
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
