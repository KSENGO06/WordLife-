import SwiftUI
import AVFAudio
struct WordCardsView: View {
    @State private var viewModel: WordCardsViewModel
    @State private var isFlipped = false
    

    init(categoryId: String, getWordsUseCase: GetWordsUseCase, audioPlayer: AudioPlayer, startWordId: String? = nil) {
          _viewModel = State(wrappedValue: WordCardsViewModel(
              categoryId: categoryId,
              getWordsUseCase: getWordsUseCase,
              audioPlayer: audioPlayer,
              startWordId: startWordId
          ))
      }
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
            } else if let word = viewModel.currentWord {
                ZStack {
                    if isFlipped {
                        cardBack(word: word)
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    } else {
                        cardFront(word: word)
                    }
                }
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .frame(height: 320)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isFlipped.toggle()
                    }
                }

                HStack {
                    Button("←") { goToPrevious() }
                        .disabled(viewModel.currentIndex == 0)
                    Spacer()
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.words.count)")
                    Spacer()
                    Button("→") { goToNext() }
                        .disabled(viewModel.currentIndex == viewModel.words.count - 1)
                }
            } else {
                Text("Немає слів")
            }
        }
        .padding()
        .task {
            await viewModel.loadWords()

            for voice in AVSpeechSynthesisVoice.speechVoices() where voice.language.hasPrefix("en") {
                print("VOICE:", voice.name, voice.language, voice.identifier)
            }
        }
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
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private func cardBack(word: Word) -> some View {
        VStack(spacing: 12) {
            Text(word.term)
                .font(.largeTitle.bold())
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .foregroundStyle(.secondary)
            }
            Button {
                viewModel.playCurrentWordAudio()
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
