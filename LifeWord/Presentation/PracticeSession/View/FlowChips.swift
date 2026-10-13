import SwiftUI

struct FlowChips: View {
    let words: [Word]
    let selectedId: String?
    let onTap: (Word) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(words) { word in
                Button {
                    onTap(word)
                } label: {
                    Text(word.translation)
                        .font(.appBodyRegular)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedId == word.id ? Color.blue.opacity(0.3) : Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
