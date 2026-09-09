import SwiftUI

struct MemorizeTranslationView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Запам'ятайте переклад")
                .font(.headline)

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

                        Text(word.translation)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            Button("Перемішати") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}
