import SwiftUI
 
struct PuzzleExerciseView: View {
    let exercise: SentenceExercise
    let buildTarget: Bool
    let categoryId: String
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
        SentenceBuilderView(
            title: "Build the phrase",
            promptText: promptText,
            correctTokens: correctTokens,
            decoys: decoys,
            categoryId: categoryId,
            audioPlayer: audioPlayer,
            audioText: exercise.sentenceTokens.joined(separator: " "),
            audioAssetName: exercise.audioAsset,
            onAnswer: onAnswer
        )
    }
}
 
