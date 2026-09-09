import SwiftUI

struct FillBlankExerciseView: View {
    let exercise: SentenceExercise
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    @State private var options: [String] = []
    @State private var selected: String?
    @State private var isChecked = false

    private var correctAnswer: String {
        exercise.sentenceTokens[exercise.targetWordIndex..<exercise.targetWordIndex + exercise.targetWordCount]
            .joined(separator: " ")
    }
    private var sentenceWithBlank: String {
        var tokens = exercise.sentenceTokens
        tokens.replaceSubrange(exercise.targetWordIndex..<exercise.targetWordIndex + exercise.targetWordCount, with: ["___"])
        return tokens.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Заповніть пропуск").font(.headline)
            Text(sentenceWithBlank)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selected = option
                    } label: {
                        Text(option)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(optionColor(for: option))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isChecked)
                }
            }
            .padding(.horizontal)
            Spacer()
            Button(isChecked ? "Продовжити" : "Перевірити") {
                if isChecked {
                    onAnswer(selected == correctAnswer)
                } else {
                    isChecked = true
                    audioPlayer.play(text: exercise.sentenceTokens.joined(separator: " "), audioAssetName: exercise.audioAsset)
                }
            }
            .disabled(selected == nil)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .onAppear {
            options = exercise.blankOptions.shuffled()
        }
    }

    private func optionColor(for option: String) -> Color {
        guard isChecked else {
            return selected == option ? Color.blue.opacity(0.3) : Color(.secondarySystemBackground)
        }
        if option == correctAnswer { return .green.opacity(0.4) }
        if option == selected { return .red.opacity(0.4) }
        return Color(.secondarySystemBackground)
    }
}
