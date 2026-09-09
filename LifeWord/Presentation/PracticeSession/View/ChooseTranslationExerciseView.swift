import SwiftUI

struct ChooseTranslationExerciseView: View {
    let word: Word
    let options: [Word]
    let direction: TranslationDirection
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void

    @State private var selectedId: String?
    @State private var isChecked = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Виберіть правильний переклад")
                .font(.headline)

            Image(word.imageAsset)
                .resizable()
                .scaledToFit()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if direction == .englishToUkrainian {
                Button {
                    audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                } label: {
                    Image(systemName: "speaker.wave.2.fill").font(.title2)
                }

                Text(word.term).font(.title3.bold())
            } else {
                Text(word.translation).font(.title3.bold())
            }

            VStack(spacing: 12) {
                ForEach(options) { option in
                    Button {
                        selectedId = option.id
                    } label: {
                        Text(direction == .englishToUkrainian ? option.translation : option.term)
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
                    onAnswer(selectedId == word.id)
                } else {
                    isChecked = true
                    audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                }
            }
            .disabled(selectedId == nil)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
    }

    private func optionColor(for option: Word) -> Color {
        guard isChecked else {
            return selectedId == option.id ? Color.blue.opacity(0.3) : Color(.secondarySystemBackground)
        }
        if option.id == word.id { return .green.opacity(0.4) }
        if option.id == selectedId { return .red.opacity(0.4) }
        return Color(.secondarySystemBackground)
    }
}
