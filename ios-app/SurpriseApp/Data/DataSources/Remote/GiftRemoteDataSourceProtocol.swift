import Foundation

protocol GiftRemoteDataSourceProtocol {
    func fetchGifts() async throws -> [Gift]
}
