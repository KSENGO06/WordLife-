import SwiftUI

/// Талісман застосунку — зображення з Assets.xcassets/mascot, за дизайном
/// Ксені (її власні SVG, перенесені напряму в imageset-и — без перемальовки).
///
/// Готові пози: `.resting` і `.waving` зараз використовуються на екрані
/// завантаження й на екрані входу. Інші (`.celebrating`, `.thinking`,
/// `.coveringEyes`, `.sad`, `.loading`, `.streak`, `.tryAgain`) вже в
/// Assets — їх можна підключити для стріку, підказок/життів, невірної
/// відповіді тощо, коли буде потрібно.
///
/// `.waving` складається з двох шарів (`mascot_waving_body` без лівої руки
/// + окремо `mascot_waving_arm`), щоб по-справжньому анімувати саме руку
/// (обертання навколо плеча), а не весь малюнок цілком.
struct MascotView: View {
    enum Pose: Equatable {
        case resting
        case waving
        case celebrating
        case thinking
        case coveringEyes
        case sad
        case loading
        case streak
        case tryAgain

        var assetName: String {
            switch self {
            case .resting: "mascot_resting"
            case .waving: "mascot_waving_body"
            case .celebrating: "mascot_celebrating"
            case .thinking: "mascot_thinking"
            case .coveringEyes: "mascot_coveringeyes"
            case .sad: "mascot_sad"
            case .loading: "mascot_loading"
            case .streak: "mascot_streak"
            case .tryAgain: "mascot_tryagain"
            }
        }
    }

    var pose: Pose = .resting
    var size: CGFloat = 256
    /// Якщо true — у позі `.waving` рука гойдається (анімація помаху).
    var animateWave: Bool = false

    @State private var waveTick = false

    /// Точка плеча лівої руки в координатах вихідного SVG (256×256) —
    /// піксель (48, 142) — переведена у частки для anchor обертання.
    private let shoulderAnchor = UnitPoint(x: 48.0 / 256.0, y: 142.0 / 256.0)

    var body: some View {
        ZStack {
            Image(pose.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            if pose == .waving {
                Image("mascot_waving_arm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(waveTick ? 18 : -6), anchor: shoulderAnchor)
            }
        }
        .onAppear {
            guard animateWave, pose == .waving else { return }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                waveTick = true
            }
        }
    }
}
