import SwiftUI
import UIKit

/// Головний екран категорії фразових дієслів — та сама вітрина, що й у
/// звичайних категоріях слів (фото сцени, чіпси зі словами, кнопки
/// "Вивчити слова" / "Закріплення"), тільки веде до PhrasalCategoryPracticeView
/// замість звичайної практики речень. Має той самий DEBUG-інструмент розмітки
/// hotspots, що й CategoryOverviewView.
struct PhrasalCategoryOverviewView: View {
    let categoryId: String
    let categoryName: String
    let getWordsUseCase: GetWordsUseCase
    let getSceneUseCase: GetSceneUseCase
    let getTranslationExercisesUseCase: GetTranslationExercisesUseCase
    let getClozeExerciseUseCase: GetClozeExerciseUseCase
    let audioPlayer: AudioPlayer

    @State private var words: [Word] = []
    @State private var scene: RoomScene?
    @State private var translationExercises: [TranslationExercise] = []
    @State private var clozeExercise: ClozeExercise?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // MARK: - Розмітка хотспотів (DEBUG-інструмент, як у CategoryOverviewView)
    // Показуємо тільки коли реально додаємо нову категорію з хотспотами —
    // на 1 поставити тут true, розмітити, повернути на false.
    private let showMarkingTool = false
    @State private var isMarkingMode = false
    @State private var placedHotspots: [String: CGPoint] = [:] // wordId -> (x,y) 0...1
    @State private var pendingTapPoint: CGPoint? = nil
    @State private var showWordPicker = false
    @State private var wordSearch = ""

    /// Слова категорії, відфільтровані пошуком у списку вибору.
    private var filteredWords: [Word] {
        guard !wordSearch.isEmpty else { return words }
        return words.filter {
            $0.term.localizedCaseInsensitiveContains(wordSearch) ||
            $0.translation.localizedCaseInsensitiveContains(wordSearch)
        }
    }

    /// Готовий JSON-масив hotspots у форматі content.json, у порядку слів категорії.
    private var hotspotsJSON: String {
        let entries = words.compactMap { word -> String? in
            guard let p = placedHotspots[word.id] else { return nil }
            return "    { \"wordId\": \"\(word.id)\", \"x\": \(String(format: "%.3f", p.x)), \"y\": \(String(format: "%.3f", p.y)) }"
        }
        return "[\n" + entries.joined(separator: ",\n") + "\n  ]"
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage).font(.appBodyRegular)
            } else if let scene {
                GeometryReader { geo in
                    let imageSize = UIImage(named: scene.imageAsset)?.size ?? geo.size
                    let scale = min(geo.size.width / imageSize.width, geo.size.height / imageSize.height)
                    let displayWidth = imageSize.width * scale
                    let displayHeight = imageSize.height * scale
                    let offsetX = (geo.size.width - displayWidth) / 2
                    let offsetY: CGFloat = 0 // фото приколоте до самого верху — без зазору під заголовком
                    // Хотспот не має ховатись під заголовком/кнопкою "назад" зверху —
                    // якщо його збережена координата потрапляє в цю зону, опускаємо його нижче.
                    let headerSafeY = geo.safeAreaInsets.top + 108

                    ZStack(alignment: .bottom) {
                        // Розмитий фон на весь екран
                        Image(scene.imageAsset)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .blur(radius: 25)
                            .overlay(Color.black.opacity(0.2))

                        // Чітка картинка по центру
                        Image(scene.imageAsset)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                            .gesture(
                                SpatialTapGesture().onEnded { value in
                                    guard isMarkingMode else { return }
                                    let localX = value.location.x - offsetX
                                    let localY = value.location.y - offsetY
                                    guard localX >= 0, localX <= displayWidth,
                                          localY >= 0, localY <= displayHeight else { return }
                                    pendingTapPoint = CGPoint(x: localX / displayWidth, y: localY / displayHeight)
                                    wordSearch = ""
                                    showWordPicker = true
                                }
                            )

                        // Хотспоти з content.json
                        ForEach(scene.hotspots, id: \.wordId) { hotspot in
                            if let word = words.first(where: { $0.id == hotspot.wordId }) {
                                Button {
                                    audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                                } label: {
                                    Text(word.term)
                                        .font(.appLabel)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.white.opacity(0.9))
                                        .clipShape(Capsule())
                                }
                                .position(
                                    x: offsetX + hotspot.x * displayWidth,
                                    y: max(offsetY + hotspot.y * displayHeight, headerSafeY)
                                )
                            }
                        }

                        // Точки, розставлені зараз у режимі розмітки (ще не в content.json)
                        if isMarkingMode {
                            ForEach(Array(placedHotspots.keys), id: \.self) { wordId in
                                if let point = placedHotspots[wordId],
                                   let word = words.first(where: { $0.id == wordId }) {
                                    Text(word.term)
                                        .font(.appCaption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(.orange)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .position(
                                            x: offsetX + point.x * displayWidth,
                                            y: offsetY + point.y * displayHeight
                                        )
                                }
                            }
                        }

                        VStack(spacing: 12) {
                            if scene.hotspots.isEmpty && !isMarkingMode {
                                wordsChipsView
                            }

                            VStack(spacing: 12) {
                                NavigationLink {
                                    WordCardsView(categoryId: categoryId, getWordsUseCase: getWordsUseCase, audioPlayer: audioPlayer)
                                } label: {
                                    Text("Learn words")
                                }
                                .buttonStyle(.primary)
                                NavigationLink {
                                    PhrasalCategoryPracticeView(
                                        categoryId: categoryId,
                                        categoryName: categoryName,
                                        words: words,
                                        translationExercises: translationExercises,
                                        clozeExercise: clozeExercise,
                                        audioPlayer: audioPlayer
                                    )
                                } label: {
                                    Text("Practice")
                                }
                                .buttonStyle(.secondary)
                            }
                        }
                        .padding()

                        #if DEBUG
                        if showMarkingTool {
                            markingPanel
                                .padding()
                                .position(x: geo.size.width - 110, y: 70)
                        }
                        #endif
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationTitle("Phrasal Verbs")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showWordPicker) {
            NavigationStack {
                List(filteredWords) { word in
                    Button {
                        assign(word: word)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(word.term).font(.appBodyRegular)
                                Text(word.translation).font(.appCaption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if placedHotspots[word.id] != nil {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .searchable(text: $wordSearch, prompt: "Пошук слова")
                .navigationTitle("Яке це слово?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Скасувати") {
                            pendingTapPoint = nil
                            showWordPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    /// Прив'язує щойно тапнуту точку до обраного слова, друкує координати в консоль
    /// і закриває список вибору.
    private func assign(word: Word) {
        guard let point = pendingTapPoint else { return }
        placedHotspots[word.id] = point
        print(String(format: "HOTSPOT: wordId=\"%@\" x=%.3f y=%.3f", word.id, point.x, point.y))
        pendingTapPoint = nil
        showWordPicker = false
    }

    /// Список слів категорії у вигляді капсул — так само, як у звичайних
    /// категоріях, поки в них немає розмічених hotspots.
    private var wordsChipsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(words) { word in
                    Button {
                        audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
                    } label: {
                        Text(word.term)
                            .font(.appLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.9))
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 160)
        .background(.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    #if DEBUG
    /// DEBUG-only панель розмітки: перемикач режиму, підказка, яке слово зараз ставимо,
    /// і кнопки копіювання/скидання. Прибирається з релізної збірки автоматично.
    private var markingPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                isMarkingMode.toggle()
            } label: {
                Text(isMarkingMode ? "Розмітка: ON" : "Розмітка: OFF")
                    .font(.appLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isMarkingMode ? .orange : .black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            if isMarkingMode {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Тапни на фото — обереш слово зі списку")
                        .font(.appCaption2)
                    Text("\(placedHotspots.count)/\(words.count) розмічено")
                        .font(.appCaption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if !placedHotspots.isEmpty {
                    HStack(spacing: 6) {
                        Button {
                            UIPasteboard.general.string = hotspotsJSON
                            print("HOTSPOTS JSON (скопійовано в буфер):\n\(hotspotsJSON)")
                        } label: {
                            Text("Копіювати JSON")
                                .font(.appCaption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        Button {
                            placedHotspots.removeAll()
                        } label: {
                            Text("Скинути")
                                .font(.appCaption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.red.opacity(0.85))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    #endif

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            words = try await getWordsUseCase.execute(categoryId: categoryId)
            scene = try await getSceneUseCase.execute(categoryId: categoryId)
            translationExercises = try await getTranslationExercisesUseCase.execute(categoryId: categoryId, words: words)
            clozeExercise = try await getClozeExerciseUseCase.execute(categoryId: categoryId)
        } catch {
            errorMessage = "Couldn't load category"
        }
        isLoading = false
    }
}
