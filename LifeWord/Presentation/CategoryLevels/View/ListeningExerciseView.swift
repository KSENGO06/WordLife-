import SwiftUI

struct ListeningExerciseView: View {
    let exercise: SentenceExercise
    let categoryId: String
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    private var sentenceText: String {
        exercise.sentenceTokens.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ExerciseTitleLabel(text: "Build what you hear")
                Spacer()
            }
            HStack(spacing: 16) {
                Button {
                    audioPlayer.play(text: sentenceText, audioAssetName: exercise.audioAsset)
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 88, height: 88)
                        .background(Color.appAccent.opacity(0.15))
                        .clipShape(Circle())
                }

                Button {
                    audioPlayer.play(text: sentenceText, audioAssetName: exercise.audioAsset, rate: 0.55)
                } label: {
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 56, height: 56)
                        .background(Color.appAccent.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 48)
            SentenceBuilderView(
                correctTokens: exercise.sentenceTokens,
                decoys: exercise.targetDecoys,
                categoryId: categoryId,
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
