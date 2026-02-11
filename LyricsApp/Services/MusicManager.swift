import Foundation
import Combine
#if canImport(MediaPlayer)
import MediaPlayer
#endif

public struct TrackInfo: Equatable {
    public let title: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval
    
    public init(title: String, artist: String, album: String, duration: TimeInterval) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
    }
}

public class MusicManager: ObservableObject {
    @Published public var currentTrack: TrackInfo?
    @Published public var isPlaying: Bool = false
    @Published public var playbackTime: TimeInterval = 0
    
    private var timer: AnyCancellable?
    
    #if os(iOS)
    private let player = MPMusicPlayerController.systemMusicPlayer
    #endif
    
    public init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        #if os(iOS)
        // Observe notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMusicPlayerControllerNowPlayingItemDidChange),
                                               name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                                               object: player)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMusicPlayerControllerPlaybackStateDidChange),
                                               name: .MPMusicPlayerControllerPlaybackStateDidChange,
                                               object: player)
        
        player.beginGeneratingPlaybackNotifications()
        
        updateNowPlayingInfo()
        updatePlaybackState()
        
        // Polling for playback time (10Hz)
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePlaybackTime()
            }
        #else
        // Stub for macOS or other platforms
        print("MusicManager: Monitoring not supported on this platform (iOS required for MPMusicPlayerController)")
        #endif
    }
    
    deinit {
        #if os(iOS)
        player.endGeneratingPlaybackNotifications()
        #endif
        timer?.cancel()
    }
    
    @objc private func handleMusicPlayerControllerNowPlayingItemDidChange() {
        updateNowPlayingInfo()
    }
    
    @objc private func handleMusicPlayerControllerPlaybackStateDidChange() {
        updatePlaybackState()
    }
    
    private func updateNowPlayingInfo() {
        #if os(iOS)
        if let item = player.nowPlayingItem {
            self.currentTrack = TrackInfo(
                title: item.title ?? "Unknown",
                artist: item.artist ?? "Unknown",
                album: item.albumTitle ?? "Unknown",
                duration: item.playbackDuration
            )
        } else {
            self.currentTrack = nil
        }
        #endif
    }
    
    private func updatePlaybackState() {
        #if os(iOS)
        self.isPlaying = player.playbackState == .playing
        #endif
    }
    
    private func updatePlaybackTime() {
        #if os(iOS)
        if self.isPlaying {
            self.playbackTime = player.currentPlaybackTime
        }
        #endif
    }
}
