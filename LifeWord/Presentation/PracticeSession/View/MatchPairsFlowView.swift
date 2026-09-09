import SwiftUI

struct MatchPairsFlowView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void

    @State private var isMemorizing = true

    var body: some View {
        if isMemorizing {
            MemorizeTranslationView(words: words, audioPlayer: audioPlayer) {
                isMemorizing = false
            }
        } else {
            MatchPairsExerciseView(words: words, audioPlayer: audioPlayer, onComplete: onComplete)
        }
    }
}
