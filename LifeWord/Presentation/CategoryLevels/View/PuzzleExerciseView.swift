import SwiftUI

struct PuzzleExerciseView: View {
    let exercise: SentenceExercise
    let buildTarget: Bool
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    private var promptText: String {
        buildTarget ? exercise.nativeText : exercise.sentenceTokens.joined(separator: " ")
    }
    private var correctTokens: [String] {
        buildTarget ? exercise.sentenceTokens : exercise.nativeText.split(separator: " ").map(String.init)
    }
    private var decoys: [String] {
        buildTarget ? exercise.targetDecoys : exercise.nativeDecoys
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Зберіть фразу").font(.headline)
            Text(promptText)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            SentenceBuilderView(
                correctTokens: correctTokens,
                decoys: decoys,
                audioPlayer: audioPlayer,
                audioText: exercise.sentenceTokens.joined(separator: " "),
                audioAssetName: exercise.audioAsset,
                onAnswer: onAnswer
            )
        }
    }
}
