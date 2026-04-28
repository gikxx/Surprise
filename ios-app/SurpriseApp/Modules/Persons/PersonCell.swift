import UIKit

// MARK: - PersonCell

final class PersonCell: UITableViewCell {

    static let identifier = "PersonCell"

    // MARK: - Views

    private let avatarView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 26
        v.layer.cornerCurve = .continuous
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let initialsLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 20)
        l.textColor = .appPrimary
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont(name: "Helvetica-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 13)
        l.textColor = UIColor.appPrimary.withAlphaComponent(0.6)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let daysLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 12)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        selectionStyle = .none

        avatarView.addSubview(initialsLabel)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(daysLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 52),
            avatarView.heightAnchor.constraint(equalToConstant: 52),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: daysLabel.leadingAnchor, constant: -8),

            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            dateLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            daysLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            daysLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            daysLabel.widthAnchor.constraint(equalToConstant: 90),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
        ])
    }

    // MARK: - Configure

    func configure(with person: Person) {
        nameLabel.text = person.name
        dateLabel.text = "\(person.eventType.emoji) \(person.eventDateString)"
        daysLabel.text = person.daysLabel

        // Цвет дней
        let days = person.daysUntilEvent
        switch days {
        case 0:
            daysLabel.textColor = UIColor(hex: "#E87C7C")
        case 1...7:
            daysLabel.textColor = UIColor(hex: "#E8A87C")
        default:
            daysLabel.textColor = UIColor.appPrimary.withAlphaComponent(0.45)
        }

        // Аватар-заглушка: первая буква имени на голубом фоне
        let initial = String(person.name.prefix(1)).uppercased()
        initialsLabel.text = initial
        avatarView.backgroundColor = UIColor(hex: "#BDD3E9").withAlphaComponent(0.5)

        // Подсветка строки если ≤14 дней
        if person.isUpcoming {
            contentView.backgroundColor = UIColor(hex: "#BDD3E9").withAlphaComponent(0.12)
        } else {
            contentView.backgroundColor = .clear
        }
    }
}
