import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties
    var window: UIWindow?
    var appCoordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        GiftDataLoader.shared.loadInitialGiftsIfNeeded()
        
        // 1. Создаем окно программно
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // 2. Инициализируем главный координатор
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator
        
        // 3. Запускаем приложение через координатор
        coordinator.start()
    }

}

