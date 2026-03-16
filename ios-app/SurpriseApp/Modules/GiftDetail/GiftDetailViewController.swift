import UIKit
import SafariServices

final class GiftDetailViewController: UIViewController {
    
    private let viewModel: GiftDetailViewModelProtocol
    
    // MARK: - Callbacks
    var onBuyTapped: (() -> Void)?
    var onBackTapped: (() -> Void)?
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // Top card
    private let topCardView = UIView()
    private let imageView = UIImageView()
    
    
    // Description
    private let nameLabel = UILabel()
    private let aboutTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let priceLabel = UILabel()
    
    // Bottom area
    private let bottomContainer = UIView()
    private let buyButton = UIButton.createPrimary(title: "к продавцу")
    private let favoriteButton = UIButton(type: .system)
    
    private let backButton = UIButton(type: .system)
    
    private let tapBarHeight: CGFloat = 60
    private let bottomPadding: CGFloat = 30
    
    // MARK: - Init
    init(viewModel: GiftDetailViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupUI()
        configure(with: viewModel.gift)
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        setupBottomContainer()
        setupScrollView()
        setupTopCard()
        setupTopCardContainer()
        setupDescription()
        setupPrice()
        setupBackButton()
        setupFavoriteButton()
    }
    
    private func setupBackButton() {
        backButton.setImage(UIImage(named: "back_icon"), for: .normal)
        backButton.tintColor = .appSecondary
        backButton.backgroundColor = .clear
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentStack.axis = .vertical
        contentStack.spacing = 20
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: -8),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupTopCard() {
        topCardView.translatesAutoresizingMaskIntoConstraints = false
        topCardView.backgroundColor = .clear
        topCardView.layer.cornerRadius = 42
        topCardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        topCardView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        topCardView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topCardView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: topCardView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: topCardView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: topCardView.bottomAnchor),
        ])
    }
    
    private func setupTopCardContainer() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(topCardView)
        topCardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topCardView.topAnchor.constraint(equalTo: container.topAnchor),
            topCardView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topCardView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topCardView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.heightAnchor.constraint(
                equalTo: container.widthAnchor,
                multiplier: 1.2
            )
        ])
        
        contentStack.addArrangedSubview(container)
    }
    
    private func setupDescription() {
        nameLabel.font = .helveticaBold(size: 23)
        nameLabel.numberOfLines = 0
        nameLabel.textColor = .appTextMain
        
        aboutTitleLabel.font = .helveticaBold(size: 15)
        aboutTitleLabel.textColor = .appTextMain
        aboutTitleLabel.text = "О бренде"
        
        descriptionLabel.font = .helveticaRegular(size: 13)
        descriptionLabel.textColor = .appTextMain
        descriptionLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [nameLabel, aboutTitleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: wrapper.topAnchor),
            stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(wrapper)
    }
    
    private func setupPrice() {
        priceLabel.font = .helveticaRegular(size: 32)
        priceLabel.textColor = .appTextMain
        
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            priceLabel.topAnchor.constraint(equalTo: wrapper.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            priceLabel.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
            priceLabel.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        
        contentStack.addArrangedSubview(wrapper)
    }
    
    private func setupFavoriteButton() {
        favoriteButton.setImage(UIImage(named: "heart_icon")?.withRenderingMode(.alwaysTemplate), for: .normal)
        favoriteButton.tintColor = viewModel.isFavorite ? .appFavActive : .appBackground
        favoriteButton.backgroundColor = .clear
        favoriteButton.addTarget(self, action: #selector(didTapFavorite), for: .touchUpInside)
    }
    
    private func setupBottomContainer() {
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.backgroundColor = .clear
        bottomContainer.isUserInteractionEnabled = true
        
        view.addSubview(bottomContainer)
        setupButtonsInsideBottomContainer()
    }
    
    private var bottomContainerBottomConstraint: NSLayoutConstraint!
    
    private func setupButtonsInsideBottomContainer() {
        buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [buyButton, favoriteButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        bottomContainer.addSubview(stack)
        
        buyButton.heightAnchor.constraint(equalToConstant: 55).isActive = true
        buyButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        favoriteButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        favoriteButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        bottomContainerBottomConstraint = bottomContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -(bottomPadding + tapBarHeight)
        )
        
        NSLayoutConstraint.activate([
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomContainer.heightAnchor.constraint(equalToConstant: 60),
            bottomContainerBottomConstraint,
            
            stack.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: bottomContainer.leadingAnchor, constant: 20)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        if let vm = viewModel as? GiftDetailViewModel {
            vm.onStateChanged = { [weak self] in
                self?.updateFavoriteState()
            }
        }
    }
    
    // MARK: - Configure
    private func configure(with gift: Gift) {
        nameLabel.text = gift.name
        priceLabel.text = "\(Int(gift.price))"
        descriptionLabel.text = gift.description
        
        ImageLoader.shared.loadImage(from: gift.imageURL) { [weak self] image in
            self?.imageView.image = image ?? UIImage(named: "gift_placeholder")
        }
        
        updateFavoriteState()
    }
    
    private func updateFavoriteState() {
        favoriteButton.tintColor = viewModel.isFavorite ? .appFavActive : .appSecondary
    }
    
    // MARK: - Actions
    @objc private func didTapFavorite() {
        viewModel.toggleFavorite()
    }
    
    @objc private func didTapBuy() {
        onBuyTapped?() 
    }
    
    @objc private func didTapBack() {
        onBackTapped?()
    }
}
