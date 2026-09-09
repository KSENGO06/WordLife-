import SwiftUI

struct FlowChips: View {
    let words: [Word]
    let selectedId: String?
    let onTap: (Word) -> Void

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(words) { word in
                Button {
                    onTap(word)
                } label: {
                    Text(word.translation)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedId == word.id ? Color.blue.opacity(0.3) : Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
