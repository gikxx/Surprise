import UIKit

final class GiftCell: UICollectionViewCell {
    static let identifier = "GiftCell"
    
    private let cardView = GiftCardView()
    
    var onFavoriteTapped: (() -> Void)? {
        get { cardView.onFavoriteTapped }
        set { cardView.onFavoriteTapped = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .appWhite
        contentView.layer.cornerRadius = 42
        contentView.clipsToBounds = true
        
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with gift: Gift) {
        cardView.configure(with: gift)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cardView.cancelImageLoad()
    }
}
