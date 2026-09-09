import SwiftUI

struct SentenceBuilderView: View {
    let correctTokens: [String]
    let decoys: [String]
    let audioPlayer: AudioPlayer
    let audioText: String
    let audioAssetName: String?
    var playsAudio: Bool = true
    let onAnswer: (Bool) -> Void

    @State private var bank: [String] = []
    @State private var answer: [String] = []
    @State private var isChecked = false
    @State private var isCorrect = false

    var body: some View {
        VStack(spacing: 20) {
            FlowLayout(spacing: 8) {
                ForEach(Array(answer.enumerated()), id: \.offset) { index, word in
                    Button {
                        answer.remove(at: index)
                        bank.append(word)
                    } label: {
                        Text(word)
                            .fixedSize()
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .disabled(isChecked)
                }
            }
            .frame(minHeight: 40)
            .padding(.horizontal)

            Divider()

            FlowLayout(spacing: 8) {
                ForEach(Array(bank.enumerated()), id: \.offset) { index, word in
                    Button {
                        bank.remove(at: index)
                        answer.append(word)
                    } label: {
                        Text(word)
                            .fixedSize()
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                    .disabled(isChecked)
                }
            }
            .padding(.horizontal)

            if isChecked {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isCorrect ? "Правильно!" : "Правильна відповідь:")
                        .font(.headline)
                    Text(correctTokens.joined(separator: " "))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }

            Spacer()

            Button(isChecked ? "Продовжити" : "Перевірити") {
                if isChecked {
                    onAnswer(isCorrect)
                } else {
                    isCorrect = answer == correctTokens
                    isChecked = true
                    if playsAudio {
                        audioPlayer.play(text: audioText, audioAssetName: audioAssetName)
                    }
                }
            }
            .disabled(!isChecked && answer.count != correctTokens.count)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .onAppear {
            bank = (correctTokens + decoys).shuffled()
        }
    }
}
