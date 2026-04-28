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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .appWhite
        layer.cornerRadius = 42
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        // Сбрасываем предыдущее состояние
        imageLoadTask?.cancel()
        currentImageURL = gift.imageURL
        imageView.image = UIImage(named: "gift_placeholder")
        
        // Загружаем новое изображение
        imageLoadTask = ImageLoader.shared.loadImage(from: gift.imageURL) { [weak self] image in
            guard let self = self else { return }
            // Проверяем, что URL всё ещё актуален для этой вьюшки
            guard self.currentImageURL == gift.imageURL else { return }
            self.imageView.image = image ?? UIImage(named: "gift_placeholder")
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
