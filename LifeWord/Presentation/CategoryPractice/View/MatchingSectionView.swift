import SwiftUI

struct MatchingSectionView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: () -> Void

    @State private var chunks: [[Word]] = []
    @State private var currentChunkIndex = 0

    private let chunkSize = 5

    var body: some View {
        
            let _ = print("🟣 MatchingSectionView.body викликано, chunks: \(chunks.count)")
            
        VStack(spacing: 16) {
            HStack {
                Button { onExit() } label: { Image(systemName: "xmark") }
                if !chunks.isEmpty {
                    ProgressView(value: Double(currentChunkIndex), total: Double(chunks.count))
                }
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                    Text("\(HeartsManager.shared.hearts)")
                }
            }
            .padding(.horizontal)

            if currentChunkIndex < chunks.count {
                MatchPairsFlowView(words: chunks[currentChunkIndex], audioPlayer: audioPlayer) {
                    currentChunkIndex += 1
                    if currentChunkIndex >= chunks.count { onComplete() }
                }
                .id(currentChunkIndex)
            }
        }
        .padding(.top)
        .onAppear { chunks = words.shuffled().chunked(into: chunkSize) }
        .onChange(of: HeartsManager.shared.hearts) { _, hearts in
            if hearts == 0 { onExit() }
        }
    }
}
