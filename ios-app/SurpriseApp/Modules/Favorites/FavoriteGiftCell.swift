import UIKit

final class FavoriteGiftCell: UICollectionViewCell {
    static let identifier = "FavoriteGiftCell"
    
    private let cardView: GiftCardView = {
        let view = GiftCardView()
        view.layer.cornerRadius = 42
        view.clipsToBounds = true
        return view
    }()
    
    private let buyButton = UIButton.createPrimary(title: "к продавцу")
    
    var onFavoriteTapped: (() -> Void)? {
        get { cardView.onFavoriteTapped }
        set { cardView.onFavoriteTapped = newValue }
    }
    var onBuyTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(cardView)
        contentView.addSubview(buyButton)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        buyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 1.25),
            
            buyButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            buyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buyButton.heightAnchor.constraint(equalToConstant: 45),
            buyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        buyButton.layer.cornerRadius = 22.5
        buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with gift: Gift) {
        cardView.configure(with: gift)
    }
    
    @objc private func didTapBuy() {
        onBuyTapped?()
    }
}
