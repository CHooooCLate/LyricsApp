import Foundation

public struct LyricsLine: Identifiable, Equatable, Codable {
    public let id: UUID
    public let time: TimeInterval
    public let text: String
    
    public init(time: TimeInterval, text: String) {
        self.id = UUID()
        self.time = time
        self.text = text
    }
    
    // Helper to format time for debugging
    public var timeString: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}
