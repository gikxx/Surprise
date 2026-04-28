import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

// MARK: - Endpoint
struct Endpoint {
    let path: String
    let method: HTTPMethod
    var queryItems: [URLQueryItem] = []
    var bodyParameters: [String: Any]? = nil
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(String)  
    case serverError(String)
    case unauthorized
    case noConnection
    case unknown
}

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    /// Для эндпоинтов, которые возвращают 204 No Content (без тела ответа).
    func requestVoid(_ endpoint: Endpoint) async throws
}

// MARK: - Network Service
final class NetworkService: NetworkServiceProtocol {
    /// Общая URLSession с укороченными таймаутами.
    /// 60 сек по дефолту убивают холодный старт, если бэкенд недоступен —
    /// пользователь видит «висящий» Feed. 15 сек на запрос и 20 на ресурс
    /// дают разумный fail-fast, после которого сработает офлайн-фолбэк
    /// в репозиториях.
    static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    private actor TokenRefreshCoordinator {
        private var refreshTask: Task<Bool, Never>?

        func runSingleRefresh(_ operation: @escaping @Sendable () async -> Bool) async -> Bool {
            if let refreshTask {
                return await refreshTask.value
            }

            let task = Task { await operation() }
            refreshTask = task
            let result = await task.value
            refreshTask = nil
            return result
        }
    }
    
    private struct RefreshTokenResponse: Decodable {
        let token: String
        let refreshToken: String?
        
        enum CodingKeys: String, CodingKey {
            case token
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            token = try container.decodeIfPresent(String.self, forKey: .token)
                ?? container.decode(String.self, forKey: .accessToken)
            refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        }
    }
    
    private static let tokenRefreshCoordinator = TokenRefreshCoordinator()
    
    private let baseURL: String
    private let session: URLSession

    init(
        baseURL: String = AppConfig.shared.apiBaseURL,
        session: URLSession = NetworkService.sharedSession
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            let (data, statusCode) = try await execute(endpoint: endpoint)
            switch statusCode {
            case 200...299:
                do {
                    return try JSONDecoder.surpriseDecoder.decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError(error.localizedDescription)
                }
            case 401:
                if shouldAttemptTokenRefresh(for: endpoint.path),
                   await refreshAccessTokenIfNeeded() {
                    let (retryData, retryStatus) = try await execute(endpoint: endpoint)
                    guard (200...299).contains(retryStatus) else {
                        notifySessionExpiredIfNeeded(for: endpoint.path)
                        throw NetworkError.unauthorized
                    }
                    
                    do {
                        return try JSONDecoder.surpriseDecoder.decode(T.self, from: retryData)
                    } catch {
                        throw NetworkError.decodingError(error.localizedDescription)
                    }
                }
                
                notifySessionExpiredIfNeeded(for: endpoint.path)
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError("HTTP \(statusCode)")
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.noConnection
        } catch {
            throw NetworkError.unknown
        }
    }
    
    func requestVoid(_ endpoint: Endpoint) async throws {
        do {
            let (_, statusCode) = try await execute(endpoint: endpoint)
            switch statusCode {
            case 200...299:
                return
            case 401:
                notifySessionExpiredIfNeeded(for: endpoint.path)
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError("HTTP \(statusCode)")
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw NetworkError.noConnection
        } catch {
            throw NetworkError.unknown
        }
    }

    private func execute(endpoint: Endpoint) async throws -> (Data, Int) {
        let request = try buildRequest(endpoint: endpoint)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        return (data, httpResponse.statusCode)
    }
    
    private func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let parameters = endpoint.bodyParameters,
           [.post, .put, .patch].contains(endpoint.method) {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        return request
    }
    
    private func shouldAttemptTokenRefresh(for path: String) -> Bool {
        !path.hasPrefix("/auth/login")
            && !path.hasPrefix("/auth/register")
            && !path.hasPrefix("/auth/refresh")
    }
    
    private func refreshAccessTokenIfNeeded() async -> Bool {
        let baseURL = self.baseURL
        let session = self.session
        
        return await Self.tokenRefreshCoordinator.runSingleRefresh {
            let refreshToken = await MainActor.run { AuthManager.shared.refreshToken }
            guard let refreshToken, !refreshToken.isEmpty else {
                return false
            }
            
            do {
                guard let url = URL(string: baseURL + "/auth/refresh") else {
                    return false
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = HTTPMethod.post.rawValue
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])
                
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return false
                }
                
                let refreshResponse = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                await MainActor.run {
                    AuthManager.shared.updateTokens(
                        token: refreshResponse.token,
                        refreshToken: refreshResponse.refreshToken
                    )
                }
                return true
            } catch {
                return false
            }
        }
    }
    
    private func notifySessionExpiredIfNeeded(for path: String) {
        guard !path.hasPrefix("/auth/") else { return }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authSessionExpired, object: nil)
        }
    }
}
