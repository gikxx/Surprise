import UIKit

final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    private let profileService: ProfileServiceProtocol
    private let settingsStore: ProfileSettingsStoreProtocol
    private let authManager = AuthManager.shared
    private var currentUser: User?

    init(
        navigationController: UINavigationController,
        profileService: ProfileServiceProtocol = ProfileService(),
        settingsStore: ProfileSettingsStoreProtocol = ProfileSettingsStore()
    ) {
        self.navigationController = navigationController
        self.profileService = profileService
        self.settingsStore = settingsStore
    }

    func start() {
        if authManager.isGuest {
            showGuestProfile()
        } else {
            loadAndShowProfile()
        }
    }

    // MARK: - Private
    
    private func showGuestProfile() {
        let guestUser = User(
            id: -1,
            name: "Гость",
            email: nil,
            phone: nil,
            isGuest: true,
            avatarUrl: nil
        )
        currentUser = guestUser
        showProfile(user: guestUser)
    }

    private func loadAndShowProfile() {
        Task {
            do {
                let user = try await profileService.fetchProfile()
                await MainActor.run {
                    // Обновляем AuthManager и кэш
                    authManager.updateUserInfo(user)
                    let settings = ProfileSettings(
                        name: user.name,
                        email: user.email ?? "",
                        phone: user.phone ?? ""
                    )
                    settingsStore.save(settings)
                    self.currentUser = user
                    showProfile(user: user)
                }
            } catch {
                await MainActor.run {
                    // Офлайн: показываем кэшированные данные
                    let cached = settingsStore.load()
                    let cachedUser = User(
                        id: authManager.userId ?? 0,
                        name: cached.name,
                        email: cached.email.isEmpty ? nil : cached.email,
                        phone: cached.phone.isEmpty ? nil : cached.phone,
                        isGuest: false,
                        avatarUrl: authManager.userAvatarUrl
                    )
                    self.currentUser = cachedUser
                    showProfile(user: cachedUser)
                    showOfflineAlert()
                }
            }
        }
    }

    private func showProfile(user: User) {
        let profileVC = ProfileViewController(user: user)
        profileVC.onSettingsTapped = { [weak self] in
            if user.isGuest {
                self?.showAuth()
            } else {
                self?.showSettings()
            }
        }
        profileVC.onSupportTapped = { [weak self] in
            self?.showSupportInfo()
        }
        profileVC.onClientInfoTapped = { [weak self] in
            self?.showClientInfo()
        }
        navigationController.setViewControllers([profileVC], animated: true)
    }

    private func showSettings() {
        guard let user = currentUser else { return }
        let settingsVC = ProfileSettingsViewController(user: user)
        settingsVC.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        settingsVC.onSave = { [weak self] name, email, phone in
            Task {
                do {
                    let updatedUser = try await self?.profileService.updateProfile(
                        name: name,
                        email: email,
                        phone: phone
                    )
                    await MainActor.run {
                        if let updatedUser = updatedUser {
                            // Обновляем AuthManager и кэш
                            self?.authManager.updateUserInfo(updatedUser)
                            let settings = ProfileSettings(
                                name: updatedUser.name,
                                email: updatedUser.email ?? "",
                                phone: updatedUser.phone ?? ""
                            )
                            self?.settingsStore.save(settings)
                            self?.currentUser = updatedUser
                            // Обновляем предыдущий экран профиля
                            if let profileVC = self?.navigationController.viewControllers.first(where: { $0 is ProfileViewController }) as? ProfileViewController {
                                profileVC.updateUser(updatedUser)
                            }
                            settingsVC.updateUser(updatedUser)
                        }
                        self?.navigationController.popViewController(animated: true)
                    }
                } catch let error as ValidationError {
                    await MainActor.run {
                        self?.showAlert(message: error.errorDescription ?? "Ошибка валидации")
                    }
                } catch let error as NetworkError {
                    await MainActor.run {
                        self?.showAlert(message: "Ошибка сети: \(error.localizedDescription)")
                    }
                } catch {
                    await MainActor.run {
                        self?.showAlert(message: "Не удалось сохранить изменения")
                    }
                }
            }
        }
        
        settingsVC.onAvatarSelected = { [weak self] avatarUrl in
            Task {
                do {
                    let updatedUser = try await self?.profileService.updateAvatar(url: avatarUrl)
                    await MainActor.run {
                        if let updatedUser = updatedUser {
                            self?.authManager.updateUserInfo(updatedUser)
                            self?.currentUser = updatedUser
                            if let profileVC = self?.navigationController.viewControllers.first(where: { $0 is ProfileViewController }) as? ProfileViewController {
                                profileVC.updateUser(updatedUser)
                            }
                            settingsVC.updateUser(updatedUser)
                        }
                    }
                } catch {
                    await MainActor.run {
                        self?.showAlert(message: "Не удалось обновить аватар")
                    }
                }
            }
        }
        navigationController.pushViewController(settingsVC, animated: true)
    }

    private func showAuth() {
        let viewModel = AuthViewModel(authService: AuthService())
        let registrationVC = RegistrationViewController(viewModel: viewModel, shouldShowBackButton: true)
        
        registrationVC.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        registrationVC.onContinue = { [weak self] in
            self?.loadAndShowProfile()
        }
        registrationVC.onSkip = { [weak self] in
            self?.authManager.setGuestSession()
            self?.showGuestProfile()
        }
        
        navigationController.pushViewController(registrationVC, animated: true)
    }

    private func showOfflineAlert() {
        let alert = UIAlertController(
            title: "Нет соединения",
            message: "Показаны сохранённые данные. Изменения будут синхронизированы при восстановлении сети.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        navigationController.topViewController?.present(alert, animated: true)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        navigationController.topViewController?.present(alert, animated: true)
    }

    private func showSupportInfo() {
        let alert = UIAlertController(
            title: "Поддержка",
            message: "Напишите нам на getmanovakarina@gmail.com",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        navigationController.topViewController?.present(alert, animated: true)
    }

    private func showClientInfo() {
        let alert = UIAlertController(
            title: "Информация",
            message: "Surprise – помогаем находить идеи подарков.\nВерсия 1.0",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        navigationController.topViewController?.present(alert, animated: true)
    }
}
