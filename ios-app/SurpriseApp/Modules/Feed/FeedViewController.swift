import UIKit

// MARK: - FeedViewController
final class FeedViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: FeedViewModelProtocol
    private var collectionView: UICollectionView!
    
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
        viewModel.loadGifts()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .appBackground
        title = viewModel.title
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        // Создаем простую сетку: 2 колонки
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        
        // MARK: - Constraints (NSLayoutAnchor)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
