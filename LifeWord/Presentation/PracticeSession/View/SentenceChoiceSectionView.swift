import SwiftUI

struct SentenceChoiceExerciseView: View {
    let exercise: SentenceChoiceExercise
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    @State private var options: [SentenceChoiceOption] = []
    @State private var selected: Set<String> = []
    @State private var isChecked = false
    @State private var showBuildCorrection = false
    @State private var rebuildAttempt = 0

    private var correctIds: Set<String> {
        Set(exercise.options.filter { $0.isCorrect }.map { $0.id })
    }
    private var isAnswerCorrect: Bool { selected == correctIds }

    private var targetOption: SentenceChoiceOption {
        exercise.options.first(where: { $0.isCorrect }) ?? exercise.options[0]
    }
    private var correctTokens: [String] {
        targetOption.text.split(separator: " ").map(String.init)
    }
    private var decoyTokens: [String] {
        let otherWords = exercise.options
            .filter { $0.id != targetOption.id }
            .flatMap { $0.text.split(separator: " ").map(String.init) }
        let correctSet = Set(correctTokens)
        let uniqueDecoys = Array(Set(otherWords.filter { !correctSet.contains($0) }))
        return Array(uniqueDecoys.shuffled().prefix(3))
    }

    var body: some View {
        if showBuildCorrection {
            VStack(spacing: 20) {
                Text("Складіть речення без помилки").font(.headline)
                Text(targetOption.translation)
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                SentenceBuilderView(
                    correctTokens: correctTokens,
                    decoys: decoyTokens,
                    audioPlayer: audioPlayer,
                    audioText: targetOption.text,
                    audioAssetName: nil,
                    playsAudio: false,
                    onAnswer: { builtCorrectly in
                        if builtCorrectly {
                            onAnswer(false)
                        } else {
                            rebuildAttempt += 1
                        }
                    }
                )
                .id(rebuildAttempt)
            }
            .padding(.top)
        } else {
            VStack(spacing: 20) {
                Text("Відмітьте 2 правильних речення")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    ForEach(options) { option in
                        Button {
                            guard !isChecked else { return }
                            if selected.contains(option.id) {
                                selected.remove(option.id)
                            } else {
                                selected.insert(option.id)
                            }
                        } label: {
                            HStack {
                                Text(option.text)
                                Spacer()
                            }
                            .padding()
                            .background(optionColor(for: option))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isChecked)
                    }
                }
                .padding(.horizontal)

                if isChecked {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isAnswerCorrect ? "Правильно!" : "Неправильно")
                            .font(.headline)
                        ForEach(exercise.options.filter { $0.isCorrect }) { option in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.text).bold()
                                Text(option.translation).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((isAnswerCorrect ? Color.green : Color.red).opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Spacer()

                Button(isChecked ? "Продовжити" : "Перевірити") {
                    if isChecked {
                        if isAnswerCorrect {
                            onAnswer(true)
                        } else {
                            showBuildCorrection = true
                        }
                    } else {
                        isChecked = true
                    }
                }
                .disabled(selected.count != 2)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .onAppear {
                options = exercise.options.shuffled()
            }
        }
    }

    private func optionColor(for option: SentenceChoiceOption) -> Color {
        guard isChecked else {
            return selected.contains(option.id) ? Color.blue.opacity(0.3) : Color(.secondarySystemBackground)
        }
        return option.isCorrect ? .green.opacity(0.4) : .red.opacity(0.4)
    }
}
