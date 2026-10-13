import UIKit

/// Фото профілю користувача — зберігається локально (JPEG у UserDefaults,
/// прив'язане до uid), та сама конвенція, що й решта менеджерів у Data/.
/// Поки без завантаження на сервер — лише на цьому пристрої.
enum AvatarStore {
    private static func key(for uid: String) -> String { "profile.avatarPhoto.\(uid)" }

    static func photo(for uid: String) -> UIImage? {
        guard !uid.isEmpty, let data = UserDefaults.standard.data(forKey: key(for: uid)) else { return nil }
        return UIImage(data: data)
    }

    /// Зменшує зображення до розумного розміру аватарки перед збереженням —
    /// фото з камери/галереї можуть бути в десятки мегабайтів, а тут треба
    /// лише маленьке коло.
    static func setPhoto(_ image: UIImage, for uid: String) {
        guard !uid.isEmpty else { return }
        let resized = resized(image, maxDimension: 320)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return }
        UserDefaults.standard.set(data, forKey: key(for: uid))
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxDimension else { return image }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
