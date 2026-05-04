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

    /// Лейбл приветствия в navigationItem.titleView.
    /// Хранится как property, чтобы обновлять имя в viewWillAppear
    /// после того как пользователь изменил его в настройках профиля.
    private let greetingLabel = UILabel()

    /// Хранит ссылку на width-constraint чипа бюджета, чтобы
    /// включать/выключать его при переходе между иконка-only ↔ иконка+текст.
    private var budgetChipWidthConstraint: NSLayoutConstraint?

    /// Чип-иконка бюджетного фильтра — фиксированный слева от скролла категорий.
    /// Неактивен: круглый чип 38×38 только с иконкой.
    /// Активен: иконка + короткий лейбл диапазона, тёмный фон.
    private lazy var budgetChipButton: UIButton = {
        // Явный размер символа — иначе UIKit рендерит иконку неконтролируемо
        let symbolCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolCfg)
        config.baseForegroundColor = .appTextSecondary
        config.baseBackgroundColor = .appSecondary
        config.cornerStyle = .capsule
        // Нулевые insets — ширина задаётся через NSLayoutConstraint (38pt),
        // UIKit центрирует иконку автоматически
        config.contentInsets = .zero
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(budgetChipTapped), for: .touchUpInside)
        return b
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollToTop),
            name: .scrollFeedToTop,
            object: nil
        )
    }

    @objc private func scrollToTop() {
        collectionView.setContentOffset(.zero, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshFavoritesState()
        applySearchBarStyle()
        refreshGreetingTitle()   // имя могло измениться в настройках профиля
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applySearchBarStyle()
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

        applySearchBarStyle()
    }
    
    private func applySearchBarStyle() {
        guard let searchBar = searchController?.searchBar else { return }
        searchBar.applyCustomStyle(
            backgroundColor: .appWhite,
            textColor: .appPrimary,
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
        collectionView.contentInsetAdjustmentBehavior = .always
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

        searchController?.searchBar.applyCapsuleCornerRadius()

        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let sectionInset: CGFloat = 16
        let interItemSpacing: CGFloat = 16
        let isRegularWidth = traitCollection.horizontalSizeClass == .regular
        let columns: CGFloat = isRegularWidth ? 3 : 2

        let usableWidth = min(view.bounds.width, isRegularWidth ? 980 : view.bounds.width)
        let horizontalPadding = max((view.bounds.width - usableWidth) / 2, sectionInset)
        layout.sectionInset = UIEdgeInsets(top: 16, left: horizontalPadding, bottom: 16, right: horizontalPadding)

        let totalHorizontalSpacing = horizontalPadding * 2 + interItemSpacing * (columns - 1)
        let itemWidth = (view.bounds.width - totalHorizontalSpacing) / columns
        let itemHeight = itemWidth * 1.25

        let newSize = CGSize(width: itemWidth, height: itemHeight)

        if layout.itemSize != newSize {
            layout.itemSize = newSize
            layout.invalidateLayout()
        }
        
        let bottomInset: CGFloat = 110
        if collectionView.contentInset.bottom != bottomInset {
            collectionView.contentInset.bottom = bottomInset
            collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }
    
    private func setupBindings() {
        if let feedViewModel = viewModel as? FeedViewModel {
            feedViewModel.onStateChanged = { [weak self] in
                self?.applyState()
            }
            feedViewModel.onFavoriteToggled = { [weak self] giftId, isFavorite in
                guard let self else { return }
                guard let index = self.viewModel.gifts.firstIndex(where: { $0.id == giftId }) else { return }
                let indexPath = IndexPath(item: index, section: 0)
                if let cell = self.collectionView.cellForItem(at: indexPath) as? GiftCell {
                    cell.updateFavoriteState(isFavorite)
                }
            }
        }
    }
    
    /// Первоначальная сборка titleView — вызывается один раз из setupUI().
    private func setupGreetingTitle() {
        let containerView = UIView()

        greetingLabel.numberOfLines = 1
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(greetingLabel)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            greetingLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            greetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            greetingLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            greetingLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            greetingLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        navigationItem.titleView = containerView

        let widthConstraint = containerView.widthAnchor.constraint(
            lessThanOrEqualToConstant: view.bounds.width - 32
        )
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true

        refreshGreetingTitle()
    }

    /// Перечитывает имя из AuthManager и обновляет текст заголовка.
    /// Вызывается при setup и при каждом viewWillAppear.
    private func refreshGreetingTitle() {
        let userName = AuthManager.shared.userName ?? "Гость"

        let attributed = NSMutableAttributedString(
            string: "Привет, ",
            attributes: [
                .font: UIFont.helveticaRegular(size: 28),
                .foregroundColor: UIColor.appPrimary
            ]
        )
        attributed.append(NSAttributedString(
            string: userName,
            attributes: [
                .font: UIFont.miama(size: 28),
                .foregroundColor: UIColor.appPrimary
            ]
        ))
        greetingLabel.attributedText = attributed
    }

    
    private func setupCategoriesView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 16)
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

        // Чип «Бюджет» — фиксированный, не скроллится вместе с категориями
        view.addSubview(budgetChipButton)
        view.addSubview(categoriesCollectionView)

        // Сохраняем width-constraint, чтобы toggle-ить его при активации фильтра
        let widthC = budgetChipButton.widthAnchor.constraint(equalToConstant: 38)
        budgetChipWidthConstraint = widthC

        NSLayoutConstraint.activate([
            // Бюджет-чип: явные 38×38 → идеальный круг с capsule-радиусом 19pt
            budgetChipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            budgetChipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            widthC,
            budgetChipButton.heightAnchor.constraint(equalToConstant: 38),

            // Категории — 8pt зазор после чипа
            categoriesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            categoriesCollectionView.leadingAnchor.constraint(equalTo: budgetChipButton.trailingAnchor, constant: 8),
            categoriesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoriesCollectionView.heightAnchor.constraint(equalToConstant: 38),
        ])
    }

    // MARK: - Budget Filter Actions

    @objc private func budgetChipTapped() {
        HapticFeedback.tap()
        let sheet = BudgetFilterBottomSheet(current: viewModel.activeBudgetFilter)
        sheet.onApply = { [weak self] filter in
            guard let self else { return }
            self.viewModel.setBudgetFilter(filter)
            self.updateBudgetChipAppearance()
        }
        present(sheet, animated: true)
    }

    /// Обновляет внешний вид чипа в зависимости от активности фильтра.
    ///
    /// Неактивен → 38×38 круг, только иконка.
    /// Активен   → пилюля: иконка + лейбл диапазона, фон .appPrimary.
    private func updateBudgetChipAppearance() {
        let filter = viewModel.activeBudgetFilter
        let isActive = filter.isActive
        let symbolCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        var config = budgetChipButton.configuration ?? .filled()

        if isActive {
            config.image = UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolCfg)
            config.title = filter.chipLabel
            config.imagePadding = 6
            config.imagePlacement = .leading
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 16)
            config.baseForegroundColor = .appWhite
            config.baseBackgroundColor = .appPrimary
            // Снимаем фиксированную ширину — кнопка вырастет под текст
            budgetChipWidthConstraint?.isActive = false
        } else {
            config.image = UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolCfg)
            config.title = nil
            config.imagePadding = 0
            config.contentInsets = .zero
            config.baseForegroundColor = .appTextSecondary
            config.baseBackgroundColor = .appSecondary
            // Возвращаем 38×38 — идеальный круг
            budgetChipWidthConstraint?.isActive = true
        }

        budgetChipButton.configuration = config
    }

    
    private func applyState() {
        collectionView.reloadData()
        categoriesCollectionView.reloadData()
        updateBudgetChipAppearance()

        if viewModel.isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }

        if viewModel.isEmpty {
            emptyLabel.text = viewModel.activeBudgetFilter.isActive
                ? "Нет подарков в этом диапазоне бюджета"
                : "Подарков пока нет"
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }

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
            HapticFeedback.selection()
            viewModel.selectCategory(at: indexPath.item)
            categoriesCollectionView.reloadData()
            onCategorySelected?(indexPath.item)
            return
        }

        if collectionView == self.collectionView {
            guard indexPath.item < viewModel.gifts.count else { return }
            HapticFeedback.tap()
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


