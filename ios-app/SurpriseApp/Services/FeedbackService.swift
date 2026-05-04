import Foundation

// MARK: - FeedbackServiceProtocol

protocol FeedbackServiceProtocol {
    func submitFeedback(message: String, email: String?) async throws
}

// MARK: - FeedbackService

final class FeedbackService: FeedbackServiceProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    func submitFeedback(message: String, email: String?) async throws {
        var params: [String: Any] = ["message": message]
        if let email = email, !email.isEmpty {
            params["email"] = email
        }
        let endpoint = Endpoint(
            path: "/feedback",
            method: .post,
            bodyParameters: params
        )
        try await networkService.requestVoid(endpoint)
    }
}
