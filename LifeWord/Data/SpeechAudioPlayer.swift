import AVFoundation

final class SpeechAudioPlayer: AudioPlayer {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    func play(text: String, audioAssetName: String?, rate: Double) {
        if let assetName = audioAssetName,
           let url = resolvedAudioURL(for: assetName) {
            player = try? AVAudioPlayer(contentsOf: url)
            // AVAudioPlayer підтримує зміну швидкості лише в діапазоні 0.5...2.0.
            player?.enableRate = true
            player?.rate = Float(min(max(rate, 0.5), 2.0))
            player?.play()
        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: AccentManager.shared.accent.speechLanguageCode)
            let scaledRate = Float(0.45 * rate)
            utterance.rate = min(max(scaledRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
            synthesizer.speak(utterance)
        }
    }

    /// Шукає файл для обраного акценту (напр. "alarm_clock_uk.mp3"); якщо його ще не
    /// згенеровано (контент переозвучується поступово), тихо повертається до базового
    /// файлу (існуюча американська озвучка).
    private func resolvedAudioURL(for assetName: String) -> URL? {
        let suffix = AccentManager.shared.accent.assetSuffix
        if !suffix.isEmpty, let accentedURL = Bundle.main.url(forResource: assetName + suffix, withExtension: "mp3") {
            return accentedURL
        }
        return Bundle.main.url(forResource: assetName, withExtension: "mp3")
    }
}
