import SwiftUI

struct ListeningExerciseView: View {
    let exercise: SentenceExercise
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    private var sentenceText: String {
        exercise.sentenceTokens.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Зберіть почуте").font(.headline)
            Button {
                audioPlayer.play(text: sentenceText, audioAssetName: exercise.audioAsset)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 44))
                    .frame(width: 88, height: 88)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.top, 8)
            SentenceBuilderView(
                correctTokens: exercise.sentenceTokens,
                decoys: exercise.targetDecoys,
                audioPlayer: audioPlayer,
                audioText: sentenceText,
                audioAssetName: exercise.audioAsset,
                onAnswer: onAnswer
            )
        }
        .onAppear {
            audioPlayer.play(text: sentenceText, audioAssetName: exercise.audioAsset)
        }
    }
}
