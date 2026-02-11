import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = LyricsViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(viewModel.trackTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(viewModel.artistName)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Lyrics Display
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.lyrics) { line in
                                Text(line.text)
                                    .font(.system(size: line == viewModel.currentLine ? 24 : 18))
                                    .fontWeight(line == viewModel.currentLine ? .bold : .regular)
                                    .foregroundColor(line == viewModel.currentLine ? .white : .gray)
                                    .opacity(line == viewModel.currentLine ? 1.0 : 0.6)
                                    .id(line.id)
                                    .animation(.easeInOut, value: viewModel.currentLine)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.currentLine) { newLine in
                        if let newLine = newLine {
                            withAnimation {
                                proxy.scrollTo(newLine.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
}
