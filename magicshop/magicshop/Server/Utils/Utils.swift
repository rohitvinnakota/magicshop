import Foundation

class Utils {
    class func getJSON(from url: URL, headers: [String: String], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                completion(.failure(error))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                completion(.success(json ?? ["":""]))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
