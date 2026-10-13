import Foundation

protocol AudioPlayer {
    /// rate: 1.0 — звичайна швидкість, менше 1.0 — повільніше (для кнопки-черепашки).
    func play(text: String, audioAssetName: String?, rate: Double)
}

extension AudioPlayer {
    /// Зручний виклик без rate — звичайна швидкість.
    func play(text: String, audioAssetName: String?) {
        play(text: text, audioAssetName: audioAssetName, rate: 1.0)
    }
}
