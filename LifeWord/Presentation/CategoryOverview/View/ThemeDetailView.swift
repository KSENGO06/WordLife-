import SwiftUI

/// The screen opened by tapping a theme card on the Categories grid: a hero
/// photo, Ukrainian title/description, a stat row, and the list of
/// subcategories inside this theme (each opening the existing
/// `CategoryOverviewView`).
struct ThemeDetailView: View {
    let theme: Theme
    let categories: [Category]
    let wordCounts: [String: Int]

    let getWordsUseCase: GetWordsUseCase
    let getSceneUseCase: GetSceneUseCase
    let getSentencesUseCase: GetSentenceExercisesUseCase
    let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    let audioPlayer: AudioPlayer

    private var content: ThemeContent.Entry {
        ThemeContent.entry(for: theme.id, fallbackName: theme.name)
    }

    private var totalWords: Int {
        categories.reduce(0) { $0 + (wordCounts[$1.id] ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ArtworkFallback(
                    preferredImageName: "theme_\(theme.id)",
                    fallbackImageNames: categories.first.map(ImageAssetResolver.candidates) ?? [],
                    symbolName: content.symbolName
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text(content.title)
                        .font(.appTitleL)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(content.subtitle)
                        .font(.appBodyRegular)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 18) {
                        Label("\(categories.count) topics", systemImage: "square.grid.2x2.fill")
                        Label("\(totalWords) words", systemImage: "text.book.closed.fill")
                    }
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryOverviewView(
                                categoryId: category.id,
                                categoryName: category.name,
                                getWordsUseCase: getWordsUseCase,
                                getSceneUseCase: getSceneUseCase,
                                getSentencesUseCase: getSentencesUseCase,
                                getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                                audioPlayer: audioPlayer
                            )
                        } label: {
                            CategoryThumbnailRow(
                                title: category.name,
                                subtitle: "\(wordCounts[category.id] ?? 0) words",
                                category: category
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .padding(.top, 12)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
