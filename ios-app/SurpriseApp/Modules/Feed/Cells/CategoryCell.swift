import UIKit

final class CategoryCell: UICollectionViewCell {

    static let identifier = "CategoryCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .helveticaRegular(size: 21)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byClipping
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 19
        contentView.clipsToBounds = true
        // contentView.heightAnchor.constraint(equalToConstant: 38).isActive = true

        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 38)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = .appTextSecondary
        contentView.backgroundColor = isSelected ? .appPrimary : .appSecondary
    }
}
