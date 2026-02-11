import Foundation

public class LyricsParser {
    
    public static func parse(lrcContent: String) -> [LyricsLine] {
        var lines: [LyricsLine] = []
        
        let pattern = #"\[(\d{1,2}):(\d{1,2})\.(\d{1,3})\](.*)"#
        let regex: NSRegularExpression
        
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            print("Regex error: \(error)")
            return []
        }
        
        // Split by new line
        let rawLines = lrcContent.components(separatedBy: .newlines)
        
        for rawLine in rawLines {
            let nsString = rawLine as NSString
            let results = regex.matches(in: rawLine, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for result in results {
                // Ensure we have enough ranges (0 is full match, 1-3 are time components, 4 is text)
                guard result.numberOfRanges >= 5 else { continue }
                
                let minutesRange = result.range(at: 1)
                let secondsRange = result.range(at: 2)
                let millisRange = result.range(at: 3)
                let textRange = result.range(at: 4)
                
                let minutesStr = nsString.substring(with: minutesRange)
                let secondsStr = nsString.substring(with: secondsRange)
                let millisStr = nsString.substring(with: millisRange)
                let text = nsString.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let min = Double(minutesStr),
                   let sec = Double(secondsStr),
                   let mil = Double(millisStr) {
                    
                    // Milliseconds can be 2 digits (.xx) or 3 digits (.xxx)
                    // If 2 digits, it's usually centiseconds (1/100). If 3, it's milliseconds.
                    // Standard LRC is often .xx (centiseconds).
                    // We treat the number after dot as a decimal part.
                    // e.g. 12.34 -> 12 + 0.34
                    // But regex captures strictly digits.
                    
                    let time: TimeInterval
                    if millisStr.count == 2 {
                        time = (min * 60) + sec + (mil / 100.0)
                    } else if millisStr.count == 3 {
                         time = (min * 60) + sec + (mil / 1000.0)
                    } else {
                        // fallback
                         time = (min * 60) + sec + (mil / 100.0)
                    }
                   
                    lines.append(LyricsLine(time: time, text: text))
                }
            }
        }
        
        return lines.sorted { $0.time < $1.time }
    }
}
