import UIKit
import SafariServices

final class FavoritesViewController: UIViewController {
    
    private let viewModel: FavoritesViewModelProtocol
    private var collectionView: UICollectionView!

    private var activeBanner: UndoBannerView?
    private var pendingBannerGiftId: Int?

    private let bannerBottomOffset: CGFloat = 100
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Ай!\nВ избранном пока пусто"
        label.font = .miama(size: 23)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .appTextMain
        return label
    }()
    
    // MARK: - Callbacks
    var onGiftSelected: ((Gift) -> Void)?
    var onBuyTapped: ((Gift) -> Void)?
    
    init(viewModel: FavoritesViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground

        setupHeader()
        setupCollectionView()
        setupEmptyState()
        bindViewModel()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollToTop),
            name: .scrollFavoritesToTop,
            object: nil
        )
    }

    @objc private func scrollToTop() {
        collectionView.setContentOffset(.zero, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadFavorites()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionLayout()
    }
    
    private func setupHeader() {
        let containerView = UIView()
        
        let label = UILabel()
        label.text = "Нравится!"
        label.font = .miama(size: 32)
        label.textColor = .appPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let widthConstraint = containerView.widthAnchor.constraint(equalToConstant: view.bounds.width - 32)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        
        navigationItem.titleView = containerView
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(FavoriteGiftCell.self, forCellWithReuseIdentifier: FavoriteGiftCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupEmptyState() {
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.applyState()
        }

        viewModel.onRemovalPending = { [weak self] giftId in
            self?.showUndoBanner(for: giftId)
        }
    }

    // MARK: - Undo Banner

    private func showUndoBanner(for giftId: Int) {
        activeBanner?.dismiss(animated: false)

        let banner = UndoBannerView()
        activeBanner = banner
        pendingBannerGiftId = giftId

        banner.onUndo = { [weak self] in
            guard let self else { return }
            self.viewModel.undoRemoval(of: giftId)
            self.activeBanner = nil
            self.pendingBannerGiftId = nil
        }

        banner.onExpired = { [weak self] in
            self?.activeBanner = nil
            self?.pendingBannerGiftId = nil
        }

        banner.show(in: view, bottomOffset: bannerBottomOffset)
    }
    
    private func applyState() {
        collectionView.reloadData()
        emptyLabel.isHidden = !viewModel.isEmpty
    }
    
    private func updateCollectionLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let bottomInset: CGFloat = 110
        if collectionView.contentInset.bottom != bottomInset {
            collectionView.contentInset.bottom = bottomInset
            collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        
        let sideInset: CGFloat = 16
        let isRegularWidth = traitCollection.horizontalSizeClass == .regular
        let columns: CGFloat = isRegularWidth ? 3 : 2
        let interItemSpacing: CGFloat = 16
        let usableWidth = min(view.bounds.width, isRegularWidth ? 980 : view.bounds.width)
        let horizontalPadding = max((view.bounds.width - usableWidth) / 2, sideInset)
        
        layout.sectionInset = UIEdgeInsets(top: 16, left: horizontalPadding, bottom: 16, right: horizontalPadding)
        layout.minimumInteritemSpacing = interItemSpacing
        layout.minimumLineSpacing = 16
        
        let totalSpacing = horizontalPadding * 2 + interItemSpacing * (columns - 1)
        let width = (view.bounds.width - totalSpacing) / columns
        layout.itemSize = CGSize(width: width, height: width * 1.25 + 8 + 45)
    }
}

extension FavoritesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gift = viewModel.items[indexPath.item]
        onGiftSelected?(gift)
    }
}

extension FavoritesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FavoriteGiftCell.identifier,
            for: indexPath
        ) as! FavoriteGiftCell
        
        let gift = viewModel.items[indexPath.item]
        cell.configure(with: gift)
        
        cell.onFavoriteTapped = { [weak self] in
            self?.viewModel.removeFromFavorites(gift.id)
        }
        
        cell.onBuyTapped = { [weak self] in
            self?.onBuyTapped?(gift) 
        }
        
        return cell
    }
}

extension FavoritesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as? UICollectionViewFlowLayout
        return layout?.itemSize ?? .zero
    }
}
