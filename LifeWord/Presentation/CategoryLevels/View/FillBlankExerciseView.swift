import SwiftUI

struct FillBlankExerciseView: View {
    let exercise: SentenceExercise
    let categoryId: String
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void
 
    @State private var options: [String] = []
    @State private var selected: String?
    @State private var isChecked = false
    @State private var hintsRemaining = 0
    @State private var showHint = false
    @State private var showHintsLimitSheet = false
 
    private var correctAnswer: String {
        // blankOptions[0] завжди відповідає правильному слову (так генеруються дані) —
        // порівнюємо з ним напряму, а не з текстом речення, бо текст речення може
        // відрізнятись від тексту кнопки: слова з подвійною назвою ("eggplant / aubergine")
        // і слова з розділовим знаком одразу після ("Durian,") ніколи не збігалися
        // з написом на кнопці, тому правильна відповідь не підсвічувалась зеленим,
        // а при виборі правильної кнопки вправа все одно рахувалась як неправильна.
        exercise.blankOptions.first ?? ""
    }
    /// Текст речення з підставленим обраним словом замість пропуску (до
    /// перевірки — акцентним кольором, після — зеленим/червоним залежно від
    /// правильності). Поки нічого не обрано — показуємо "___".
    private var sentenceView: some View {
        let tokens = exercise.sentenceTokens
        let prefix = tokens[..<exercise.targetWordIndex].joined(separator: " ")
        let suffixTokens = tokens[(exercise.targetWordIndex + exercise.targetWordCount)...]
        let suffix = suffixTokens.joined(separator: " ")
        let filler = selected ?? "___"

        return (
            Text(prefix.isEmpty ? "" : prefix + " ")
            + Text(filler)
                .foregroundColor(blankColor)
                .underline(selected != nil)
            + Text(suffix.isEmpty ? "" : " " + suffix)
        )
    }

    private var blankColor: Color {
        guard isChecked else { return .white }
        return matches(selected, correctAnswer) ? Color.appCorrect : Color.appIncorrect
    }
 
    private func matches(_ a: String?, _ b: String) -> Bool {
        guard let a else { return false }
        return a.caseInsensitiveCompare(b) == .orderedSame
    }
 
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ExerciseTitleLabel(text: "Fill in the blank")
                Spacer()

                if !isChecked {
                    Button {
                        useHint()
                    } label: {
                        Label(HintsManager.shared.isUnlimited ? "∞" : "\(hintsRemaining)", systemImage: "lightbulb.fill")
                            .font(.appHeadline)
                    }
                }
            }
            .padding(.horizontal)

            sentenceView
                .font(.appTitleM)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 56)
 
            if showHint {
                Text(exercise.nativeText)
                    .font(.appSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
 
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selected = option
                    } label: {
                        Text(option)
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
            .padding(.horizontal, 20)
            Spacer()
            Button(isChecked ? "Continue" : "Check") {
                if isChecked {
                    onAnswer(matches(selected, correctAnswer))
                } else {
                    isChecked = true
                    audioPlayer.play(text: exercise.sentenceTokens.joined(separator: " "), audioAssetName: exercise.audioAsset)
                }
            }
            .disabled(selected == nil)
            .buttonStyle(.primary)
            .padding(.horizontal, 20)
        }
        .onAppear {
            options = exercise.blankOptions.shuffled()
            hintsRemaining = HintsManager.shared.remainingHints(for: categoryId)
        }
        .sheet(isPresented: $showHintsLimitSheet) {
            LimitReachedSheetView(kind: .hints(categoryId: categoryId))
        }
    }
 
    private func useHint() {
        guard HintsManager.shared.useHint(for: categoryId) else {
            showHintsLimitSheet = true
            return
        }
        hintsRemaining = HintsManager.shared.remainingHints(for: categoryId)
        withAnimation {
            showHint = true
        }
    }
 
    private func optionColor(for option: String) -> Color {
        guard isChecked else {
            return selected == option ? Color.appAccent : Color.appAccent.opacity(0.75)
        }
        if matches(option, correctAnswer) { return Color.appCorrect }
        if option == selected { return Color.appIncorrect }
        return Color.appAccent.opacity(0.75)
    }
}
