import SwiftUI

/// Спільний конструктор речення зі слів-плиток — використовується і в
/// "Зберіть фразу" (PuzzleExerciseView), і в "Переклади речення"
/// (TranslationExerciseFlowView). Слова, які вже поставлені у відповідь,
/// лежать на підкресленій смузі зверху (як у макеті); банк невикористаних
/// слів — знизу. Після перевірки все від першого розходження з правильною
/// відповіддю підсвічується червоним, а нижче показується повна правильна
/// відповідь з кнопкою озвучки.
///
/// Підказка (лампочка з лічильником у шапці, як у "Заповніть пропуск")
/// ставить наступне правильне слово з банку в кінець відповіді — спільний
/// ліміт підказок на категорію (HintsManager), той самий, що й у тесті.
struct SentenceBuilderView: View {
    /// nil ховає і заголовок, і лампочку-підказку, і картку з реченням —
    /// для ListeningExerciseView, де свій заголовок і кнопка-динамік зверху,
    /// а показувати текст речення не можна (це видасть відповідь на слух).
    var title: String? = nil
    var promptText: String? = nil
    let correctTokens: [String]
    let decoys: [String]
    let categoryId: String
    let audioPlayer: AudioPlayer
    let audioText: String
    let audioAssetName: String?
    var playsAudio: Bool = true
    let onAnswer: (Bool) -> Void

    @State private var bank: [String] = []
    @State private var answer: [String] = []
    @State private var isChecked = false
    @State private var isCorrect = false
    @State private var hintsRemaining = 0
    @State private var showHintsLimitSheet = false

    /// Індекс першого слова у відповіді, яке розходиться з правильною —
    /// воно і все, що йде після нього, підсвічуємо червоним.
    private var firstMistakeIndex: Int? {
        for (index, word) in answer.enumerated() where index >= correctTokens.count || word != correctTokens[index] {
            return index
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 20) {
            if title != nil {
                header
            }

            // Статичний відступ зверху (не Spacer) — щоб секція опускалась нижче
            // одразу з відкриття вправи, а не тільки після якоїсь взаємодії.
            Group {
                if promptText != nil {
                    promptCard
                }

                answerStrip
            }
            .padding(.top, 48)

            bankArea

            Spacer()

            if isChecked {
                answerReveal
            }
            checkButton
        }
        .onAppear {
            bank = (correctTokens + decoys).shuffled()
            hintsRemaining = HintsManager.shared.remainingHints(for: categoryId)
        }
        .sheet(isPresented: $showHintsLimitSheet) {
            LimitReachedSheetView(kind: .hints(categoryId: categoryId))
        }
    }

    // MARK: - Заголовок + підказка

    private var header: some View {
        HStack {
            ExerciseTitleLabel(text: title ?? "")
            Spacer()

            if !isChecked {
                Button {
                    useHint()
                } label: {
                    Label(HintsManager.shared.isUnlimited ? "∞" : "\(hintsRemaining)", systemImage: "lightbulb.fill")
                        .font(.appHeadline)
                }
                .disabled(answer.count >= correctTokens.count)
            }
        }
        .padding(.horizontal)
    }

    private var promptCard: some View {
        Text(promptText ?? "")
            .font(.appTitleM)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.appAccent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
    }

    // MARK: - Смуга з розміщеними словами (підкреслена лінія знизу, як у макеті)

    private var answerStrip: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(answer.enumerated()), id: \.offset) { index, word in
                Button {
                    guard !isChecked else { return }
                    answer.remove(at: index)
                    bank.append(word)
                } label: {
                    Text(word)
                        .font(.appHeadline)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .foregroundStyle(chipTextColor(atAnswerIndex: index))
                        .background(chipBackground(atAnswerIndex: index))
                        .clipShape(Capsule())
                }
                .disabled(isChecked)
            }
        }
        .frame(minHeight: 44, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 1)
                .padding(.horizontal)
        }
    }

    private func chipBackground(atAnswerIndex index: Int) -> Color {
        guard isChecked else { return Color.appAccent }
        if let firstMistakeIndex, index >= firstMistakeIndex {
            return Color.appIncorrect
        }
        return Color.appCorrect
    }

    private func chipTextColor(atAnswerIndex index: Int) -> Color {
        .white
    }

    // MARK: - Банк ще не використаних слів

    private var bankArea: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(bank.enumerated()), id: \.offset) { index, word in
                Button {
                    bank.remove(at: index)
                    answer.append(word)
                } label: {
                    Text(word)
                        .font(.appHeadline)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color.appAccent.opacity(0.85))
                        .clipShape(Capsule())
                }
                .disabled(isChecked)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Правильна відповідь після перевірки

    private var answerReveal: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isCorrect ? "Correct!" : "Correct answer:")
                    .font(.custom("Inter-Bold", size: 20))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Button {
                    audioPlayer.play(text: audioText, audioAssetName: audioAssetName)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(isCorrect ? Color.appCorrect : Color.appIncorrect)
                }
            }
            Text(correctTokens.joined(separator: " "))
                .font(.custom("Inter-Medium", size: 16))
                .foregroundStyle(isCorrect ? Color.primary : Color.appIncorrect)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? Color.appCorrect.opacity(0.12) : Color.appIncorrect.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private var checkButton: some View {
        Button(isChecked ? "Continue" : "Check") {
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
        .buttonStyle(.primary)
        .padding(.horizontal)
    }

    // MARK: - Підказка: ставить наступне правильне слово в кінець відповіді

    private func useHint() {
        guard answer.count < correctTokens.count else { return }
        guard HintsManager.shared.useHint(for: categoryId) else {
            showHintsLimitSheet = true
            return
        }
        hintsRemaining = HintsManager.shared.remainingHints(for: categoryId)
        let correctWord = correctTokens[answer.count]
        if let bankIndex = bank.firstIndex(of: correctWord) {
            bank.remove(at: bankIndex)
            withAnimation {
                answer.append(correctWord)
            }
        }
    }
}
