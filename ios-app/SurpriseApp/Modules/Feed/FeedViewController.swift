import UIKit

// MARK: - FeedViewController
final class FeedViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: FeedViewModelProtocol
    private var collectionView: UICollectionView!
    private var searchController: UISearchController!
    private var categoriesCollectionView: UICollectionView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Подарков пока нет"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Callbacks
    var onGiftSelected: ((Gift) -> Void)?
    var onCategorySelected: ((Int) -> Void)?
    
    // MARK: - Init
    init(viewModel: FeedViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        setupBindings()
        viewModel.loadInitial()
    }
    
    override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.refreshFavoritesState()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .appBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        
        setupGreetingTitle()
        setupCategoriesView()
        setupCollectionView()
        setupStateViews()
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        let searchBar = searchController.searchBar
        
        searchBar.applyCustomStyle(
            backgroundColor: .appWhite,
            textColor: .appBackground,
            placeholderColor: .appBackground,
            placeholderText: "что я хочу...",
            iconColor: .appBackground
        )
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(GiftCell.self, forCellWithReuseIdentifier: GiftCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(
                    equalTo: categoriesCollectionView.bottomAnchor,
                    constant: 12
                ),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupStateViews() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let sectionInset: CGFloat = 16
        let interItemSpacing: CGFloat = 16

        let totalHorizontalSpacing = sectionInset * 2 + interItemSpacing
        let itemWidth = (view.bounds.width - totalHorizontalSpacing) / 2
        let itemHeight = itemWidth * 1.25

        let newSize = CGSize(width: itemWidth, height: itemHeight)

        if layout.itemSize != newSize {
            layout.itemSize = newSize
            layout.invalidateLayout()
        }
    }
    
    private func setupBindings() {
        if let feedViewModel = viewModel as? FeedViewModel {
            feedViewModel.onStateChanged = { [weak self] in
                self?.applyState()
            }
        }
    }
    
    private func setupGreetingTitle() {
        let containerView = UIView()
        
        let label = UILabel()
        let attributedString = NSMutableAttributedString()
        
        let userName = AuthManager.shared.userName ?? "Гость"
        
        let helloText = NSAttributedString(
            string: "Привет, ",
            attributes: [
                .font: UIFont.helveticaRegular(size: 28),
                .foregroundColor: UIColor.appPrimary
            ]
        )
        
        let nameText = NSAttributedString(
            string: userName,
            attributes: [
                .font: UIFont.miama(size: 28),
                .foregroundColor: UIColor.appPrimary
            ]
        )
        
        attributedString.append(helloText)
        attributedString.append(nameText)
        label.attributedText = attributedString
        label.numberOfLines = 1
        
        containerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.titleView = containerView
        
        let widthConstraint = containerView.widthAnchor.constraint(lessThanOrEqualToConstant: view.bounds.width - 32)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
    }

    
    private func setupCategoriesView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        categoriesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        categoriesCollectionView.backgroundColor = .clear
        categoriesCollectionView.showsHorizontalScrollIndicator = false
        categoriesCollectionView.translatesAutoresizingMaskIntoConstraints = false

        categoriesCollectionView.register(
            CategoryCell.self,
            forCellWithReuseIdentifier: CategoryCell.identifier
        )

        categoriesCollectionView.dataSource = self
        categoriesCollectionView.delegate = self

        view.addSubview(categoriesCollectionView)
        
        NSLayoutConstraint.activate([
            categoriesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 38)
        ])
    }

    
    private func applyState() {
        collectionView.reloadData()
        categoriesCollectionView.reloadData()
        
        if viewModel.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        emptyLabel.isHidden = !viewModel.isEmpty
        
        if let message = viewModel.errorMessage {
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension FeedViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return viewModel.categories.count
        }
        return viewModel.gifts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CategoryCell.identifier,
                for: indexPath
            ) as? CategoryCell else {
                return UICollectionViewCell()
            }
            
            let category = viewModel.categories[indexPath.item]
            let isSelected = indexPath.item == viewModel.selectedCategoryIndex
            cell.configure(title: category, isSelected: isSelected)
            
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: GiftCell.identifier,
            for: indexPath
        ) as? GiftCell else {
            return UICollectionViewCell()
        }
        
        guard indexPath.item < viewModel.gifts.count else {
            return cell
        }
        
        let gift = viewModel.gifts[indexPath.item]
        cell.configure(with: gift)
        
        cell.onFavoriteTapped = { [weak self] in
            self?.viewModel.toggleFavorite(for: gift.id)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            viewModel.selectCategory(at: indexPath.item)
            categoriesCollectionView.reloadData()
            onCategorySelected?(indexPath.item)  
            return
        }

        
        if collectionView == self.collectionView {
            guard indexPath.item < viewModel.gifts.count else { return }
            let gift = viewModel.gifts[indexPath.item]
            onGiftSelected?(gift)
        }
    }
}


// MARK: - UISearchResultsUpdating
extension FeedViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        viewModel.searchGifts(query: query)
    }
}


