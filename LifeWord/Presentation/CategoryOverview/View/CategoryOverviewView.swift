import SwiftUI
import UIKit

struct CategoryOverviewView: View {
    @State private var viewModel: CategoryOverviewViewModel
    private let getWordsUseCase: GetWordsUseCase
    private let getSentencesUseCase: GetSentenceExercisesUseCase
    private let getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase
    private let audioPlayer: AudioPlayer
    private let categoryId: String
    private let categoryName: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - Розмітка хотспотів (DEBUG-інструмент)
    // Показуємо тільки коли реально додаємо нову категорію з хотспотами —
    // на 1 поставити тут true, розмітити, повернути на false.
    private let showMarkingTool = false
    @State private var isMarkingMode = false
    @State private var placedHotspots: [String: CGPoint] = [:] // wordId -> (x,y) 0...1
    @State private var pendingTapPoint: CGPoint? = nil
    @State private var showWordPicker = false
    @State private var wordSearch = ""

    init(categoryId: String, categoryName: String, getWordsUseCase: GetWordsUseCase, getSceneUseCase: GetSceneUseCase, getSentencesUseCase: GetSentenceExercisesUseCase, getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase, audioPlayer: AudioPlayer) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        _viewModel = State(wrappedValue: CategoryOverviewViewModel(
            categoryId: categoryId,
            getWordsUseCase: getWordsUseCase,
            getSceneUseCase: getSceneUseCase
        ))
        self.getWordsUseCase = getWordsUseCase
        self.getSentencesUseCase = getSentencesUseCase
        self.getSentenceChoicesUseCase = getSentenceChoicesUseCase
        self.audioPlayer = audioPlayer
    }

    /// Слова категорії, відфільтровані пошуком у списку вибору.
    private var filteredWords: [Word] {
        guard !wordSearch.isEmpty else { return viewModel.words }
        return viewModel.words.filter {
            $0.term.localizedCaseInsensitiveContains(wordSearch) ||
            $0.translation.localizedCaseInsensitiveContains(wordSearch)
        }
    }

    /// Готовий JSON-масив hotspots у форматі content.json, у порядку слів категорії.
    private var hotspotsJSON: String {
        let entries = viewModel.words.compactMap { word -> String? in
            guard let p = placedHotspots[word.id] else { return nil }
            return "    { \"wordId\": \"\(word.id)\", \"x\": \(String(format: "%.3f", p.x)), \"y\": \(String(format: "%.3f", p.y)) }"
        }
        return "[\n" + entries.joined(separator: ",\n") + "\n  ]"
    }

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    Text(error).font(.appBodyRegular)
                } else if let scene = viewModel.scene {
                    GeometryReader { geo in
                        let imageSize = UIImage(named: scene.imageAsset)?.size ?? geo.size
                        let scale = min(geo.size.width / imageSize.width, geo.size.height / imageSize.height)
                        let displayWidth = imageSize.width * scale
                        let displayHeight = imageSize.height * scale
                        let offsetX = (geo.size.width - displayWidth) / 2
                        let offsetY: CGFloat = 0 // фото приколоте до самого верху — без зазору під заголовком
                        // Хотспот не має ховатись під заголовком/кнопкою "назад" зверху —
                        // якщо його збережена координата потрапляє в цю зону, опускаємо його нижче.
                        let headerSafeY = geo.safeAreaInsets.top + 50

                        ZStack(alignment: .bottom) {
                            // Розмитий фон — заповнює весь екран, ховає порожні смуги
                            Image(scene.imageAsset)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .blur(radius: 25)
                                .overlay(Color.black.opacity(0.2))

                            // Чітка картинка по центру — вписана цілком, нічого не обрізано
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

                            // Збережені хотспоти з content.json
                            ForEach(scene.hotspots, id: \.wordId) { hotspot in
                                if let word = viewModel.words.first(where: { $0.id == hotspot.wordId }) {
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
                                       let word = viewModel.words.first(where: { $0.id == wordId }) {
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
                                        CategoryPracticeView(
                                            categoryId: categoryId,
                                            categoryName: categoryName,
                                            getWordsUseCase: getWordsUseCase,
                                            getSentencesUseCase: getSentencesUseCase,
                                            getSentenceChoicesUseCase: getSentenceChoicesUseCase,
                                            audioPlayer: audioPlayer)
                                    } label: {
                                        Text("Practice words")
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

            headerOverlay
        }
        .task { await viewModel.load() }
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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

    /// Кнопка "назад" + назва категорії й кількість слів, поверх фото сцени.
    /// Лише кнопка "назад" поверх фото — назву категорії й кількість слів
    /// прибрали з цього екрана (вона й так видно з попереднього екрана).
    /// Без затемнення-градієнта позаду: білий кружечок кнопки й так добре
    /// видно на будь-якому фото, а сам градієнт лишав сірувату смугу зверху.
    private var headerOverlay: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.9), in: Circle())
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Список слів цієї категорії у вигляді капсул — тимчасова заміна хотспотам,
    /// поки на фото немає розмітки координат (scene.hotspots порожній).
    /// Тап по слову програє вимову, як і тап по хотспоту.
    private var wordsChipsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(viewModel.words) { word in
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
                    Text("\(placedHotspots.count)/\(viewModel.words.count) розмічено")
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
}

#Preview {
    NavigationStack {
        CategoryOverviewView(
            categoryId: "bedroom",
            categoryName: "Bedroom",
            getWordsUseCase: GetWordsUseCase(repository: BundledJSONContentRepository()),
            getSceneUseCase: GetSceneUseCase(repository: BundledJSONContentRepository()),
            getSentencesUseCase: GetSentenceExercisesUseCase(repository: BundledJSONContentRepository()),
            getSentenceChoicesUseCase: GetSentenceChoiceExercisesUseCase(repository: BundledJSONContentRepository()),
            audioPlayer: SpeechAudioPlayer()
        )
    }
}
