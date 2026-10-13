import Foundation

struct ClozeExercise: Identifiable, Codable {
    let id: String
    let categoryId: String
   
    let paragraphTemplate: String
    /// Банк слів для вибору (базові форми, без відмінювання) — показати гравцю як варіанти.
    let wordBank: [String]
    let blanks: [ClozeBlank]
    /// Повний текст з уже вставленими правильними відповідями (для звірки і для аудіо).
    let solvedText: String
    let audioAsset: String
}
 
struct ClozeBlank: Identifiable, Codable {
    var id: Int { index }
    let index: Int
    let wordId: String
    /// Правильна форма слова саме в цьому реченні (наприклад "started off", а не "start off").
    let correctForm: String
    /// Лише те речення (не весь абзац), де стоїть цей пропуск — інші пропуски в
    /// цьому ж реченні вже заповнені правильною відповіддю. Зручно для вправи
    /// "одне речення за раз" з варіантами з wordBank.
    let contextSentence: String
}
