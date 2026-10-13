import SwiftUI

struct MatchingSectionView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void
    let onExit: () -> Void

    @State private var chunks: [[Word]] = []
    @State private var currentChunkIndex = 0
    @State private var showHeartsLimitSheet = false

    private let chunkSize = 5

    var body: some View {
        let _ = print("🟣 MatchingSectionView.body викликано, chunks: \(chunks.count)")
        Group {
            if currentChunkIndex < chunks.count {
                VStack(spacing: 16) {
                    HStack {
                        Button { onExit() } label: { Image(systemName: "xmark") }
                        ProgressView(value: Double(currentChunkIndex), total: Double(chunks.count))
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill").foregroundStyle(.red)
                            Text(HeartsManager.shared.isUnlimited ? "∞" : "\(HeartsManager.shared.hearts)").font(AppFont.interBold(17)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.horizontal, 20)

                    MatchPairsFlowView(words: chunks[currentChunkIndex], audioPlayer: audioPlayer) {
                        currentChunkIndex += 1
                        if currentChunkIndex >= chunks.count { onComplete() }
                    }
                    .id(currentChunkIndex)
                }
                .padding(.top, 24)
            } else {
                // Усі чанки пройдені (або ще не завантажились при старті) —
                // не показуємо "голий" заголовок з прогресом/серцями.
                Color.clear
            }
        }
        .onAppear { chunks = words.shuffled().chunked(into: chunkSize) }
        .onChange(of: HeartsManager.shared.hearts) { _, hearts in
            if hearts == 0 { showHeartsLimitSheet = true }
        }
        .sheet(isPresented: $showHeartsLimitSheet, onDismiss: { onExit() }) {
            LimitReachedSheetView(kind: .hearts)
        }
    }
}
