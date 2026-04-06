import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
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
}

// MARK: - Network Service
final class NetworkService: NetworkServiceProtocol {
    private let baseURL: String
    private let session: URLSession

    init(
        baseURL: String = AppConfig.shared.apiBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
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
        
        if let token = AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let parameters = endpoint.bodyParameters,
           endpoint.method == .post || endpoint.method == .put {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            let dataString = String(data: data, encoding: .utf8) ?? ""
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noData
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder.surpriseDecoder
                    return try decoder.decode(T.self, from: data)
                    
                } catch {
                    throw NetworkError.decodingError(error.localizedDescription)
                }
            case 401:
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            if let urlError = error as? URLError,
               urlError.code == .notConnectedToInternet {
                throw NetworkError.noConnection
            } else if let networkError = error as? NetworkError {
                throw networkError
            } else {
                throw NetworkError.unknown
            }
        }
    }
}
