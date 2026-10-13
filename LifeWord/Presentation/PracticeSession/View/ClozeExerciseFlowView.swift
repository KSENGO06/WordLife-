import SwiftUI
import AVFoundation
import Observation

/// Показує весь абзац одразу (не по одному реченню за раз): текст тече як
/// звичайний параграф зі словами-плитками, а пропуски {{N}} — це тапабельні
/// капсули. Тап по пропуску одразу відкриває меню зі словами, які туди можна
/// вставити (ще не використані в інших пропусках); вибір у меню — і слово
/// одразу встає на місце. Тап по вже заповненому пропуску теж відкриває меню —
/// можна змінити відповідь або прибрати її назад у банк.
///
/// Кнопка-динамік (наша озвучка ElevenLabs, exercise.audioAsset) активна
/// тільки ПІСЛЯ того, як людина натиснула "Перевірити" — щоб озвучка не
/// видавала правильні відповіді заздалегідь.
struct ClozeWholeTextView: View {
    let exercise: ClozeExercise
    let audioPlayer: AudioPlayer
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var audioController = ClozeAudioController()

    /// filled[index пропуску] = слово з банку, яке зараз туди вставлене
    @State private var filled: [Int: String] = [:]
    @State private var usedBankWords: Set<String> = []
    @State private var isChecked = false
    @State private var shuffledBank: [String] = []

    private var blanks: [ClozeBlank] { exercise.blanks.sorted { $0.index < $1.index } }
    private var availableBank: [String] { shuffledBank.filter { !usedBankWords.contains($0) } }
    private var allFilled: Bool { blanks.allSatisfy { filled[$0.index] != nil } }
    private var correctCount: Int { blanks.filter(isBlankCorrect).count }

    private func isBlankCorrect(_ blank: ClozeBlank) -> Bool {
        guard let word = filled[blank.index] else { return false }
        return word.caseInsensitiveCompare(blank.correctForm) == .orderedSame
            || blank.correctForm.lowercased().contains(word.lowercased())
    }

    /// Слова, доступні для конкретного пропуску в меню: усі ще не використані
    /// + те слово, що вже стоїть саме в цьому пропуску (щоб можна було або
    /// лишити його, або замінити на інше).
    private func menuOptions(for index: Int) -> [String] {
        var options = availableBank
        if let current = filled[index], !options.contains(current) {
            options.insert(current, at: 0)
        }
        return options
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                ExerciseTitleLabel(text: isChecked ? "Correct: \(correctCount) of \(blanks.count)" : "Tap a blank and choose a word")
                Spacer()
                Button {
                    audioController.loadIfNeeded(assetName: exercise.audioAsset)
                    audioController.toggle()
                } label: {
                    Image(systemName: audioController.isPlaying ? "pause.fill" : "speaker.wave.2.fill")
                }
                .disabled(!isChecked)
                .opacity(isChecked ? 1 : 0.3)
            }
            .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    paragraphView
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 28)

                    if isChecked {
                        let wrongOnes = blanks.filter { !isBlankCorrect($0) }
                        if !wrongOnes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Correct answers:").font(.appLabel).lineLimit(1).minimumScaleFactor(0.7)
                                ForEach(wrongOnes) { blank in
                                    Text("\(filled[blank.index] ?? "—") → \(blank.correctForm)")
                                        .font(.appCaption)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    } else if !availableBank.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Still left to fill in:").font(.appCaption).foregroundStyle(.secondary)
                            FlowLayout(spacing: 8) {
                                ForEach(availableBank, id: \.self) { word in
                                    Text(word)
                                        .font(.appCaption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            Button(isChecked ? "Finish" : "Check") {
                if isChecked {
                    onComplete()
                } else {
                    isChecked = true
                }
            }
            .disabled(!allFilled)
            .buttonStyle(.primary)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top, 24)
        .onAppear {
            if shuffledBank.isEmpty { shuffledBank = exercise.wordBank.shuffled() }
        }
        .onDisappear {
            audioController.stop()
        }
    }

    /// Абзац як потік окремих "слів"-фрагментів у FlowLayout: звичайний текст
    /// не інтерактивний, а пропуски — капсули з меню вибору слова.
    private var paragraphView: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                switch token {
                case .word(let w):
                    Text(w)
                        .font(AppFont.interMedium(19))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                case .blank(let index):
                    Menu {
                        ForEach(menuOptions(for: index), id: \.self) { word in
                            Button(word) { place(word, at: index) }
                        }
                        if filled[index] != nil {
                            Divider()
                            Button("Remove", role: .destructive) { clear(index) }
                        }
                    } label: {
                        Text(filled[index] ?? "_____")
                            .font(AppFont.interMedium(19))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(blankColor(index))
                            .underline()
                    }
                    .disabled(isChecked)
                }
            }
        }
    }

    private var tokens: [ParagraphToken] {
        var result: [ParagraphToken] = []
        var rest = Substring(exercise.paragraphTemplate)
        while let open = rest.range(of: "{{") {
            let before = rest[rest.startIndex..<open.lowerBound]
            result.append(contentsOf: before.split(whereSeparator: { $0.isWhitespace }).map { .word(String($0)) })
            rest = rest[open.upperBound...]
            guard let close = rest.range(of: "}}") else { break }
            if let number = Int(rest[rest.startIndex..<close.lowerBound]) {
                result.append(.blank(number))
            }
            rest = rest[close.upperBound...]
        }
        result.append(contentsOf: rest.split(whereSeparator: { $0.isWhitespace }).map { .word(String($0)) })
        return result
    }

    private func blankColor(_ index: Int) -> Color {
        if isChecked, let blank = blanks.first(where: { $0.index == index }) {
            return isBlankCorrect(blank) ? Color.appCorrect : Color.appIncorrect
        }
        return filled[index] == nil ? .blue : .primary
    }

    private func place(_ word: String, at index: Int) {
        guard !isChecked else { return }
        if let old = filled[index] { usedBankWords.remove(old) }
        filled[index] = word
        usedBankWords.insert(word)
    }

    private func clear(_ index: Int) {
        guard !isChecked else { return }
        if let word = filled[index] {
            filled[index] = nil
            usedBankWords.remove(word)
        }
    }
}

private enum ParagraphToken {
    case word(String)
    case blank(Int)
}

/// Керує програванням готового аудіо (наша озвучка ElevenLabs, exercise.audioAsset)
/// з можливістю поставити на паузу й продовжити з того самого місця —
/// AVAudioPlayer.pause()/.play() самі зберігають позицію.
@Observable
private final class ClozeAudioController: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    var isPlaying = false

    func loadIfNeeded(assetName: String) {
        guard player == nil, let url = Self.resolvedAudioURL(for: assetName) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
    }

    /// Та ж логіка, що в SpeechAudioPlayer: спершу шукає файл обраного акценту
    /// (напр. "cloze_1_uk.mp3"), і тихо повертається до базового файлу, якщо
    /// британську версію ще не згенеровано.
    private static func resolvedAudioURL(for assetName: String) -> URL? {
        let suffix = AccentManager.shared.accent.assetSuffix
        if !suffix.isEmpty, let accentedURL = Bundle.main.url(forResource: assetName + suffix, withExtension: "mp3") {
            return accentedURL
        }
        return Bundle.main.url(forResource: assetName, withExtension: "mp3")
    }

    func toggle() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        player.currentTime = 0
    }
}
