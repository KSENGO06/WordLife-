import AVFoundation

final class SpeechAudioPlayer: AudioPlayer {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    func play(text: String, audioAssetName: String?) {
        if let assetName = audioAssetName,
           let url = Bundle.main.url(forResource: assetName, withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.play()
        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.45
            synthesizer.speak(utterance)
        }
    }
}
