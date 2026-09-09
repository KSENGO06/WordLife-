import Observation

@Observable
final class WordCardsViewModel {
    private let getWordsUseCase: GetWordsUseCase
    private let audioPlayer: AudioPlayer
    private let categoryId: String
    private let startWordId: String?
    var words: [Word] = []
    var currentIndex: Int = 0
    var isLoading = false
    var errorMessage: String?
    
    
    init(categoryId: String, getWordsUseCase: GetWordsUseCase, audioPlayer: AudioPlayer, startWordId: String? = nil) {
        self.categoryId = categoryId
        self.getWordsUseCase = getWordsUseCase
        self.audioPlayer = audioPlayer
        self.startWordId = startWordId
    }
    
    @MainActor
    func loadWords() async {
        isLoading = true
        errorMessage = nil
        do {
            words = try await getWordsUseCase.execute(categoryId: categoryId)
            if let startWordId, let idx = words.firstIndex(where: { $0.id == startWordId }) {
                currentIndex = idx
            }
        } catch {
            errorMessage = "Failed to load words"
        }
        isLoading = false
    }
    var currentWord: Word? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }
    func next() {
        guard currentIndex < words.count - 1 else  { return }
        currentIndex += 1
    }
    func previous() {
        guard currentIndex > 0 else  { return }
        currentIndex -= 1
    }
    func playCurrentWordAudio() {
        guard let word = currentWord else { return }
        audioPlayer.play(text: word.term, audioAssetName: word.audioAsset)
    }
}
