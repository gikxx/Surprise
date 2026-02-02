import UIKit

final class FinalOnboardingViewController: UIViewController {
    
    // MARK: - Properties
    var onCompletion: (() -> Void)?
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ура!"
        label.font = .miama(size: 86)
        label.textColor = .appPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "бегом выбирать подарки"
        label.font = .helveticaRegular(size: 34)
        label.textColor = .appPrimary
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()
    
    private let blueStar: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "star")
        iv.tintColor = .appImageBlue.withAlphaComponent(0.4)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let brownStar: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "star")
        iv.tintColor = .appSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.completeOnboarding()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        [titleLabel, subtitleLabel, brownStar, blueStar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            blueStar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140),
            blueStar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            blueStar.widthAnchor.constraint(equalToConstant: 88),
            blueStar.heightAnchor.constraint(equalToConstant: 100),
            
            brownStar.centerXAnchor.constraint(equalTo: blueStar.centerXAnchor),
            brownStar.bottomAnchor.constraint(equalTo: blueStar.topAnchor, constant: 0),
            brownStar.widthAnchor.constraint(equalToConstant: 88),
            brownStar.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.widthAnchor.constraint(equalToConstant: 265),
            subtitleLabel.widthAnchor.constraint(equalToConstant: 280),
            
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 42),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -20),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 42),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
        ])
        
        animateAppearance()
    }
    
    private func animateAppearance() {
        blueStar.alpha = 0
        brownStar.alpha = 0
        titleLabel.alpha = 0
        subtitleLabel.alpha = 0
        
        UIView.animate(withDuration: 0.8, delay: 0.2, options: .curveEaseOut) {
            self.blueStar.alpha = 1
            self.brownStar.alpha = 1
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.8, options: .curveEaseOut) {
            self.titleLabel.alpha = 1
            self.subtitleLabel.alpha = 1
        }
    }
    
    private func completeOnboarding() {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0
        }) { _ in
            self.onCompletion?()
        }
    }
}
