import Foundation
import Combine

public enum LyricsError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case notFound
}

public struct LRCLibResponse: Codable {
    public let id: Int
    public let trackName: String
    public let artistName: String
    public let albumName: String
    public let duration: Double
    public let syncedLyrics: String?
    public let plainLyrics: String?
}

public class LyricsService {
    private let session: URLSession
    private let baseURL = "https://lrclib.net/api/get"
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchLyrics(track: String, artist: String, album: String, duration: TimeInterval) -> AnyPublisher<String, LyricsError> {
        guard var components = URLComponents(string: baseURL) else {
            return Fail(error: LyricsError.invalidURL).eraseToAnyPublisher()
        }
        
        components.queryItems = [
            URLQueryItem(name: "track_name", value: track),
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "album_name", value: album),
            URLQueryItem(name: "duration", value: String(Int(duration)))
        ]
        
        guard let url = components.url else {
            return Fail(error: LyricsError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .mapError { LyricsError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<String, LyricsError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: LyricsError.networkError(URLError(.badServerResponse))).eraseToAnyPublisher()
                }
                
                if httpResponse.statusCode == 404 {
                    // Start of fallback logic can go here if needed, or just return notFound
                    return Fail(error: LyricsError.notFound).eraseToAnyPublisher()
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: LyricsError.networkError(URLError(.badServerResponse))).eraseToAnyPublisher()
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                return Just(data)
                    .decode(type: LRCLibResponse.self, decoder: decoder)
                    .mapError { LyricsError.decodingError($0) }
                    .tryMap { response in
                        guard let lyrics = response.syncedLyrics else {
                            throw LyricsError.notFound
                        }
                        return lyrics
                    }
                    .mapError { $0 as? LyricsError ?? LyricsError.decodingError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
