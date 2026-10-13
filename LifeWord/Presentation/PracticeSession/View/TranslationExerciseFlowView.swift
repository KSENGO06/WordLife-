import SwiftUI

/// Проходить по всіх вправах "переклади речення" категорії одну за одною:
/// показує українське речення, а гравець складає англійський переклад
/// зі слів-плиток (правильні токени + кілька приманок з інших речень
/// категорії) — той самий механізм, що й у PuzzleExerciseView/SentenceBuilderView
/// для звичайних слів.
struct TranslationExerciseFlowView: View {
    let exercises: [TranslationExercise]
    let categoryId: String
    let audioPlayer: AudioPlayer
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var isFinished = false

    /// Пул усіх слів з answerTokens усіх вправ категорії — джерело приманок.
    private var allTokensPool: [String] {
        exercises.flatMap { $0.answerTokens }
    }

    private func decoys(for exercise: TranslationExercise) -> [String] {
        let correct = Set(exercise.answerTokens.map { $0.lowercased() })
        let pool = Array(Set(allTokensPool)).filter { !correct.contains($0.lowercased()) }
        return Array(pool.shuffled().prefix(4))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                if !isFinished {
                    ProgressView(value: Double(currentIndex), total: Double(exercises.count))
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            if isFinished {
                resultView
            } else if let exercise = exercises[safe: currentIndex] {
                SentenceBuilderView(
                    title: "Translate the sentence into English",
                    promptText: exercise.nativeText,
                    correctTokens: exercise.answerTokens,
                    decoys: decoys(for: exercise),
                    categoryId: categoryId,
                    audioPlayer: audioPlayer,
                    audioText: exercise.answerText,
                    audioAssetName: exercise.audioAsset,
                    onAnswer: { isCorrect in
                        if isCorrect { correctCount += 1 }
                        advance()
                    }
                )
                .id(exercise.id)
            } else {
                ProgressView()
            }
        }
        .padding(.top, 24)
    }

    private func advance() {
        if currentIndex + 1 < exercises.count {
            currentIndex += 1
        } else {
            isFinished = true
            onComplete()
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: correctCount == exercises.count ? "star.fill" : "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Done!").font(.appTitleL).lineLimit(1).minimumScaleFactor(0.7)
            Text("Correct: \(correctCount) of \(exercises.count)")
                .font(.appBodyRegular)
                .foregroundStyle(.secondary)
            Button("Close") { dismiss() }
                .buttonStyle(.primary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
