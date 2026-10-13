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
        VStack(spacing: 16) {
            HStack {
                ExerciseTitleLabel(text: "Choose the correct translation")
                Spacer()
            }

            // Без картки/фону навколо — саме зображення, на всю ширину екрана
            // (як перелік відповідей), трохи більше за розміром.
            // Статичний відступ зверху (не Spacer) — щоб секція опускалась нижче
            // одразу з відкриття вправи, а не тільки після якоїсь взаємодії.
            Image(word.imageAsset)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 240)
                .padding(.horizontal)
                .padding(.top, 40)

            HStack(spacing: 10) {
                if direction == .englishToUkrainian {
                    Button {
                        audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill").font(.appHeadline)
                    }
                    Text(word.term).font(.custom("Inter-Bold", size: 21)).lineLimit(1).minimumScaleFactor(0.7)
                } else {
                    Text(word.translation).font(.custom("Inter-Bold", size: 21)).lineLimit(1).minimumScaleFactor(0.7)
                }
            }

            VStack(spacing: 12) {
                ForEach(options) { option in
                    Button {
                        selectedId = option.id
                    } label: {
                        Text(direction == .englishToUkrainian ? option.translation : option.term)
                            .font(AppFont.interMedium(17))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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

            Button(isChecked ? "Continue" : "Check") {
                if isChecked {
                    onAnswer(selectedId == word.id)
                } else {
                    isChecked = true
                    audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                }
            }
            .disabled(selectedId == nil)
            .buttonStyle(.primary)
            .padding(.horizontal)
        }
    }

    private func optionColor(for option: Word) -> Color {
        guard isChecked else {
            return selectedId == option.id ? Color.appAccent : Color.appAccent.opacity(0.75)
        }
        if option.id == word.id { return Color.appCorrect }
        if option.id == selectedId { return Color.appIncorrect }
        return Color.appAccent.opacity(0.75)
    }
}
