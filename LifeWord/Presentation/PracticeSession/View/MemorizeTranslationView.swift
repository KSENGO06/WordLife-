import SwiftUI

struct MemorizeTranslationView: View {
    let words: [Word]
    let audioPlayer: AudioPlayer
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ExerciseTitleLabel(text: "Memorize the translation")
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(words) { word in
                    HStack(spacing: 12) {
                        Button {
                            audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                        } label: {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text(word.term)
                                    .font(.appBodyRegular)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Text(word.translation)
                            .font(.appBodyRegular)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 40)

            Spacer()

            Button("Shuffle") {
                onContinue()
            }
            .buttonStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}
