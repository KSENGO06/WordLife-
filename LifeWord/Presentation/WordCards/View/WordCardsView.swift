import SwiftUI
import AVFAudio

struct WordCardsView: View {
    @State private var viewModel: WordCardsViewModel
    @State private var isFlipped = false
    @Environment(\.dismiss) private var dismiss

    init(categoryId: String, getWordsUseCase: GetWordsUseCase, audioPlayer: AudioPlayer, startWordId: String? = nil) {
        _viewModel = State(wrappedValue: WordCardsViewModel(
            categoryId: categoryId,
            getWordsUseCase: getWordsUseCase,
            audioPlayer: audioPlayer,
            startWordId: startWordId
        ))
    }

    private var progress: Double {
        guard !viewModel.words.isEmpty else { return 0 }
        return Double(viewModel.currentIndex + 1) / Double(viewModel.words.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Group {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(error).font(.appBodyRegular).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let word = viewModel.currentWord {
                    VStack(spacing: 20) {
                        ZStack {
                            if isFlipped {
                                cardBack(word: word)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            } else {
                                cardFront(word: word)
                            }
                        }
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isFlipped.toggle()
                            }
                        }

                        Text(isFlipped ? " " : "Tap to see the word")
                            .font(.appBodySmall)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                } else {
                    Text("No words").font(.appBodyRegular).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            bottomBar
        }
        .appScreenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadWords()
        }
    }

    // MARK: - Верхня панель: закрити, прогрес, лічильник

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule().fill(Color.appAccent).frame(width: max(6, geo.size.width * progress))
                }
            }
            .frame(height: 6)

            Text("\(viewModel.words.isEmpty ? 0 : viewModel.currentIndex + 1) / \(viewModel.words.count)")
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Нижня панель: попереднє / наступне слово

    private var bottomBar: some View {
        HStack {
            Button {
                goToPrevious()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(viewModel.currentIndex == 0 ? Color(.tertiaryLabel) : .primary)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1.5))
            }
            .disabled(viewModel.currentIndex == 0)

            Spacer()

            Button {
                goToNext()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.appAccent, in: Circle())
            }
            .disabled(viewModel.words.isEmpty || viewModel.currentIndex == viewModel.words.count - 1)
            .opacity(viewModel.words.isEmpty || viewModel.currentIndex == viewModel.words.count - 1 ? 0.4 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    private func goToNext() {
        isFlipped = false
        viewModel.next()
    }

    private func goToPrevious() {
        isFlipped = false
        viewModel.previous()
    }

    @ViewBuilder
    private func cardFront(word: Word) -> some View {
        Image(word.imageAsset)
            .resizable()
            .scaledToFit()
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    @ViewBuilder
    private func cardBack(word: Word) -> some View {
        VStack(spacing: 14) {
            Text(word.term)
                .font(AppFont.playfairBold(34))
                .multilineTextAlignment(.center)
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .font(.appBodyRegular)
                    .foregroundStyle(.secondary)
            }
            Button {
                viewModel.playCurrentWordAudio()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.appAccent.opacity(0.12), in: Circle())
            }
            Text(word.translation)
                .font(.appHeadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
