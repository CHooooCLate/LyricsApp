import Foundation
import Combine

public class LyricsViewModel: ObservableObject {
    @Published public var lyrics: [LyricsLine] = []
    @Published public var currentLine: LyricsLine?
    @Published public var nextLine: LyricsLine?
    
    // For UI display
    @Published public var trackTitle: String = "No Track"
    @Published public var artistName: String = "Unknown Artist"
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private var musicManager: MusicManager
    private var lyricsService: LyricsService
    private var cancellables = Set<AnyCancellable>()
    
    public init(musicManager: MusicManager = MusicManager(), lyricsService: LyricsService = LyricsService()) {
        self.musicManager = musicManager
        self.lyricsService = lyricsService
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Track changes -> Fetch lyrics
        musicManager.$currentTrack
            .removeDuplicates()
            .sink { [weak self] track in
                guard let self = self, let track = track else {
                    self?.resetLyrics()
                    return
                }
                
                self.trackTitle = track.title
                self.artistName = track.artist
                self.fetchLyrics(for: track)
            }
            .store(in: &cancellables)
        
        // Playback time changes -> Update current line
        musicManager.$playbackTime
            .sink { [weak self] time in
                self?.updateCurrentLine(currentTime: time)
            }
            .store(in: &cancellables)
    }
    
    private func resetLyrics() {
        self.lyrics = []
        self.currentLine = nil
        self.nextLine = nil
        self.trackTitle = "No Track"
        self.artistName = ""
    }
    
    private func fetchLyrics(for track: TrackInfo) {
        self.isLoading = true
        self.errorMessage = nil
        
        lyricsService.fetchLyrics(track: track.title, artist: track.artist, album: track.album, duration: track.duration)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load lyrics: \(error)"
                    print("Lyrics fetch error: \(error)")
                }
            }, receiveValue: { [weak self] lrcString in
                guard let self = self else { return }
                self.lyrics = LyricsParser.parse(lrcContent: lrcString)
                // Initial update
                self.updateCurrentLine(currentTime: self.musicManager.playbackTime)
            })
            .store(in: &cancellables)
    }
    
    private func updateCurrentLine(currentTime: TimeInterval) {
        guard !lyrics.isEmpty else { return }
        
        // Find the last line that has a time <= currentTime
        // Optimization: Could cache index, but robust lookup is safer for seeking.
        
        let validLines = lyrics.filter { $0.time <= currentTime }
        guard let last = validLines.last else {
            // Before first line
            self.currentLine = nil
            self.nextLine = lyrics.first
            return
        }
        
        if self.currentLine != last {
            self.currentLine = last
            
            // Find next line
            if let index = lyrics.firstIndex(of: last), index + 1 < lyrics.count {
                self.nextLine = lyrics[index + 1]
            } else {
                self.nextLine = nil
            }
            
            // Here we would clear update Live Activity / Widget if needed
            // WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
