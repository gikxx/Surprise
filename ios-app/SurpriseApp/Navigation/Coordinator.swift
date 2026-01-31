import UIKit

// MARK: - Coordinator Protocol
protocol Coordinator: AnyObject {
    
    // MARK: Properties
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    // MARK: Methods
    func start()
}
