import UIKit

/// UINavigationController, который разрешает свайп-назад даже когда
/// navigationBar скрыт (стандартное поведение iOS его отключает).
final class SwipeNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SwipeNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Разрешаем жест только когда есть экран, куда возвращаться
        return viewControllers.count > 1
    }
}
