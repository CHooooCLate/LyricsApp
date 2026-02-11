import WidgetKit
import SwiftUI

#if canImport(WidgetKit) && canImport(SwiftUI)
struct LyricsWidgetEntry: TimelineEntry {
    let date: Date
    let lyricLine: String
    let nextLyricLine: String
}

struct LyricsProvider: TimelineProvider {
    func placeholder(in context: Context) -> LyricsWidgetEntry {
        LyricsWidgetEntry(date: Date(), lyricLine: "Current Lyric Line", nextLyricLine: "Next Lyric Line")
    }

    func getSnapshot(in context: Context, completion: @escaping (LyricsWidgetEntry) -> ()) {
        let entry = LyricsWidgetEntry(date: Date(), lyricLine: "Singing...", nextLyricLine: "Next...")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LyricsWidgetEntry>) -> ()) {
        // In a real app, this would fetch shared data from UserDefaults or AppGroup
        // Logic to predict updates would be needed for precise timing (batching frames)
        // For now, static update example
        let entry = LyricsWidgetEntry(date: Date(), lyricLine: "Synced Lyric", nextLyricLine: "Upcoming...")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct LyricsWidgetEntryView: View {
    var entry: LyricsProvider.Entry

    var body: some View {
        ZStack {
            Color.black
            VStack {
                Text(entry.lyricLine)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(entry.nextLyricLine)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct LyricsWidget: Widget {
    let kind: String = "LyricsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LyricsProvider()) { entry in
            LyricsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lyrics")
        .description("Shows current lyrics.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
#endif

