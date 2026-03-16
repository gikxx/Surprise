import UIKit

final class ImageLoader {
    
    static let shared = ImageLoader()
    
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    @discardableResult
    func loadImage(
        from urlString: String,
        completion: @escaping (UIImage?) -> Void
    ) -> URLSessionDataTask? {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil
        }
        
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }
        
        let task = session.dataTask(with: url) { [weak self] data, _, error in
            guard
                let self,
                error == nil,
                let data,
                let image = UIImage(data: data)
            else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            self.cache.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.resume()
        return task
    }
}

