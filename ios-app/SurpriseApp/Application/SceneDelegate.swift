import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // MARK: - Properties
    var window: UIWindow?
    var appCoordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // 1. Создаем окно программно
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // 2. Инициализируем главный координатор
        let coordinator = AppCoordinator(window: window)
        self.appCoordinator = coordinator

        // 3. Запускаем приложение через координатор
        coordinator.start()

        // 4. Загружаем начальные данные в фоне — после того как UI уже показан
        DispatchQueue.global(qos: .background).async {
            GiftDataLoader.shared.loadInitialGiftsIfNeeded()
        }

        // 5. In-app баннер о ближайшем празднике (если ≤ 14 дней).
        NotificationManager.shared.showInAppBannerIfNeeded()
    }

    // Вызывается когда приложение открывается по URL (в т.ч. из виджета)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        if url.scheme == "surprise" && url.host == "feed" {
            NotificationCenter.default.post(name: .openFeedTab, object: nil)
        }
    }

}
