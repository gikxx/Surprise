import UIKit

final class OnboardingContainerViewController: UIViewController {
    var onFinish: (() -> Void)?
    private var pageViewController: UIPageViewController!
    private var pages: [UIViewController] = []
    
    private let skipButton = UIButton.createSecondary(title: "пропустить")
    private let backButton = UIButton.createRound(imageName: "arrow.left")
    private let nextButton = UIButton.createRound(imageName: "arrow.right")
    private let finishButton = UIButton.createPrimary(title: "в приложение")
    
    private let pageControl = UIPageControl()
    
    private let steps: [OnboardingPageModel] = [
    OnboardingPageModel(
        title: "Что тебя ждет в приложении?",
        description: "",
        imageName: "wewewe",
    ),
    OnboardingPageModel(
        title: "Подборки",
        description: "Мы находимся в постоянном поиске! В наших подборках вы можете найти товары от локальных брендов, а также незаурядные идеи по вашему запросу.",
        imageName: "star4",
    ),
    OnboardingPageModel(
        title: "Избранное",
        description: "Мы даем вам полный контроль над тем, что вы храните и чем делитесь.",
        imageName: "tree",
    ),
    OnboardingPageModel(
        title: "Коммьюнити",
        description: "Наше приложение – это экосистема, в которой вы можете находиться в постоянном диалоге с новыми брендами и узнавать о российском сообществе еще больше и делиться идеями с друзьями!",
        imageName: "ellipse",
    ),
    OnboardingPageModel(
        title: "Ура!",
        description: "бегом выбирать подарки",
        imageName: "star",
    )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupPages()
        setupPageViewController()
        setupUI()
        updateInterface(for: 0)
    }
    
    private func setupPages() {
        pages = steps.map { model in
            OnboardingPageViewController(model: model)
        }
    }
    
    private func setupUI() {
        [skipButton, backButton, nextButton, finishButton, pageControl].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        pageControl.numberOfPages = steps.count
        pageControl.currentPage = 0

        NSLayoutConstraint.activate([
            // Точки в самом низу
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Кнопка "в приложение" (строго по центру над точками)
            finishButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            finishButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            finishButton.widthAnchor.constraint(equalToConstant: 220),
            finishButton.heightAnchor.constraint(equalToConstant: 55),

            // Пропустить - слева
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            skipButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -20),
            skipButton.widthAnchor.constraint(equalToConstant: 120),
            skipButton.heightAnchor.constraint(equalToConstant: 40),

            // Навигация - справа
            backButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -12),
            backButton.centerYAnchor.constraint(equalTo: skipButton.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 55),
            backButton.heightAnchor.constraint(equalToConstant: 55),
            
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            nextButton.centerYAnchor.constraint(equalTo: skipButton.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 55),
            nextButton.heightAnchor.constraint(equalToConstant: 55),
            
        ])

        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        finishButton.addTarget(self, action: #selector(didTapFinish), for: .touchUpInside)
    }
    
    private func updateInterface(for index: Int) {
        pageControl.currentPage = index
        let isLastPage = (index == pages.count - 1)
        
        finishButton.isHidden = !isLastPage
        
        skipButton.isHidden = isLastPage
        backButton.isHidden = isLastPage || (index == 0)
        nextButton.isHidden = isLastPage
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let firstPage = pages.first {
            pageViewController.setViewControllers([firstPage], direction: .forward, animated: true)
        }
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func didTapNext() {
        let nextIndex = pageControl.currentPage + 1
        if nextIndex < pages.count {
            goToPage(index: nextIndex)
        } else {
            onFinish?()
        }
    }

    @objc private func didTapBack() {
        let prevIndex = pageControl.currentPage - 1
        if prevIndex >= 0 {
            goToPage(index: prevIndex)
        }
    }

    @objc private func didTapFinish() {
        onFinish?() 
    }

    @objc private func didTapSkip() {
        onFinish?()
    }

    private func goToPage(index: Int) {
        let direction: UIPageViewController.NavigationDirection = index > pageControl.currentPage ? .forward : .reverse
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: true)
        updateInterface(for: index)
    }
    

}

// MARK: - UIPageViewControllerDataSource & Delegate
extension OnboardingContainerViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let visibleVC = pageViewController.viewControllers?.first,
           let index = pages.firstIndex(of: visibleVC) {
            updateInterface(for: index)
        }
    }
}
