import SwiftUI

struct MatchPairsExerciseView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onComplete: () -> Void

    @State private var chipPool: [Word] = []
    @State private var placedWordForSlot: [String: Word] = [:]
    @State private var selectedChipId: String?
    @State private var isChecked = false
    @State private var wrongSlotIds: Set<String> = []

    private var hasWrong: Bool { !wrongSlotIds.isEmpty }

    var body: some View {
        VStack(spacing: 20) {
            Text("Соотнесите слова\nз правильним перекладом")
                .font(.headline)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(words) { word in
                    HStack(spacing: 12) {
                        Button {
                            audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                        } label: {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text(word.term)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        slotView(for: word)
                    }
                }
            }
            .padding(.horizontal)

            FlowChips(words: chipPool, selectedId: selectedChipId) { chip in
                selectedChipId = (selectedChipId == chip.id) ? nil : chip.id
            }
            .padding(.horizontal)

            Spacer()

            Button(buttonTitle) {
                if isChecked {
                    if hasWrong {
                        retryWrong()
                    } else {
                        onComplete()
                    }
                } else {
                    check()
                }
            }
            .disabled(placedWordForSlot.count < words.count)
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .onAppear {
            chipPool = words.shuffled()
        }
    }

    private var buttonTitle: String {
        guard isChecked else { return "Перевірити" }
        return hasWrong ? "Спробувати ще раз" : "Продовжити"
    }

    @ViewBuilder
    private func slotView(for word: Word) -> some View {
        Button {
            guard !isChecked else { return }
            if let placed = placedWordForSlot[word.id] {
                chipPool.append(placed)
                placedWordForSlot[word.id] = nil
            } else if let chipId = selectedChipId, let chip = chipPool.first(where: { $0.id == chipId }) {
                placedWordForSlot[word.id] = chip
                chipPool.removeAll { $0.id == chipId }
                selectedChipId = nil
            }
        } label: {
            Text(placedWordForSlot[word.id]?.translation ?? "")
                .frame(maxWidth: .infinity)
                .padding()
                .background(slotColor(for: word))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: placedWordForSlot[word.id] == nil ? 1.5 : 0, dash: [5]))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func slotColor(for word: Word) -> Color {
        if isChecked {
            if wrongSlotIds.contains(word.id) { return .red.opacity(0.3) }
            return placedWordForSlot[word.id] != nil ? .green.opacity(0.3) : Color(.secondarySystemBackground)
        }
        return placedWordForSlot[word.id] != nil ? Color.blue.opacity(0.2) : Color(.secondarySystemBackground)
    }

    private func check() {
        wrongSlotIds = Set(words.filter { placedWordForSlot[$0.id]?.id != $0.id }.map { $0.id })
        isChecked = true
        if !wrongSlotIds.isEmpty {
            HeartsManager.shared.loseHeart()
        }
    }

    /// Правильні пари лишаються на місці, неправильні повертаються в пул для повторної спроби
    private func retryWrong() {
        for id in wrongSlotIds {
            if let chip = placedWordForSlot[id] {
                chipPool.append(chip)
                placedWordForSlot[id] = nil
            }
        }
        wrongSlotIds = []
        isChecked = false
    }
}
