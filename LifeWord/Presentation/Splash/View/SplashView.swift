import SwiftUI

/// Екран завантаження: талісман махає рукою в центрі, навколо нього влітають
/// і осідають слова колом. Показується один раз при запуску, далі застосунок
/// переходить до звичайної кореневої розв'язки (вхід або головний екран).
struct SplashView: View {
    let onFinished: () -> Void

    @State private var showWords = false

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    private let cream = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF3 / 255)
    private let ink = Color(red: 27.0 / 255, green: 27.0 / 255, blue: 27.0 / 255)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            VStack {
                Text("WORDS FOR REAL LIFE")
                    .font(.appCaption2)
                    .tracking(2.5)
                    .foregroundStyle(.secondary)
                    .padding(.top, 24)
                Spacer()
            }

            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.46)
                // Зона слів тепер вища за талісмана: купка росте знизу вгору
                // (головний принцип), але верх зони піднімається вище за його
                // голову, щоб слова могли "засипати" його і зверху.
                let wordsCenter = CGPoint(x: center.x, y: center.y + 10)
                let clusterSize = CGSize(
                    width: min(geo.size.width * 0.94, 400),
                    height: 440
                )
                ZStack {
                    if showWords {
                        FallingWordsView(center: wordsCenter, clusterSize: clusterSize)
                    }
                    MascotView(pose: .waving, size: 220, animateWave: true)
                        .position(center)
                }
            }

            VStack {
                Spacer()
                VStack(spacing: 14) {
                    Text("GATHERING YOUR WORDS")
                        .font(.appCaption2)
                        .tracking(2)
                        .foregroundStyle(ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ink)
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(ink.opacity(0.25), lineWidth: 1.2))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation { showWords = true }
            }
            // Контент застосунку (content.json) уже повністю завантажений і
            // розпарсений до того, як цей екран взагалі з'явився —
            // BundledJSONContentRepository() ініціалізується синхронно в
            // LifeWordApp.init, ще до побудови RootView. Тобто реальне
            // завантаження вже закінчилось в момент появи сплеша: чекати
            // тут нема на що, і прив'язуватись до тривалості анімації
            // падіння слів не треба — екран просто показує бренд-момент
            // коротко й одразу пускає далі, а не тримає користувача, доки
            // долетить і осяде останнє слово.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
    }
}
#Preview {
    SplashView(onFinished: {})
}
