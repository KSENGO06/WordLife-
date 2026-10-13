import Foundation

/// Ukrainian display copy for each `Theme` (the top-level grid cards on the
/// Categories screen) plus a fallback SF Symbol for when no photo is bundled
/// yet. The theme/category *content* itself (English words being taught)
/// stays in content.json — this is purely UI chrome layered on top of it.
enum ThemeContent {
    struct Entry {
        let title: String
        let subtitle: String
        let symbolName: String
    }

    private static let entries: [String: Entry] = [
        "home": Entry(title: "At Home", subtitle: "Words for your home and everyday life.", symbolName: "house.fill"),
        "doctor": Entry(title: "Health", subtitle: "Words for self-care and understanding healthcare.", symbolName: "cross.case.fill"),
        "food": Entry(title: "Food & Drinks", subtitle: "Words about food, dishes, and drinks.", symbolName: "fork.knife"),
        "outside": Entry(title: "Around Town", subtitle: "Words about your yard, housing, and getting around the city.", symbolName: "map.fill"),
        "character-emotions": Entry(title: "Character & Emotions", subtitle: "Words about personality, emotions, and future plans.", symbolName: "face.smiling.fill"),
        "kids": Entry(title: "Kids", subtitle: "Words about pregnancy, babies, and children's things.", symbolName: "figure.2.and.child.holdinghands"),
        "family": Entry(title: "People & Relationships", subtitle: "Words about family and relationships.", symbolName: "person.2.fill"),
        "work": Entry(title: "Work & Career", subtitle: "Words about the office, job titles, and careers.", symbolName: "briefcase.fill"),
        "education": Entry(title: "Education", subtitle: "Words about learning and school.", symbolName: "book.fill"),
        "travel": Entry(title: "Travel", subtitle: "Words about transportation and travel.", symbolName: "airplane"),
        "technology": Entry(title: "Technology", subtitle: "Words about gadgets and the internet.", symbolName: "desktopcomputer"),
        "money": Entry(title: "Shopping & Money", subtitle: "Words about shopping and finances.", symbolName: "cart.fill"),
        "nature": Entry(title: "Nature", subtitle: "Words about the environment and nature.", symbolName: "leaf.fill"),
        "weather": Entry(title: "Weather", subtitle: "Words about weather and seasons.", symbolName: "cloud.sun.fill"),
        "sport": Entry(title: "Sports", subtitle: "Words about sports and physical activity.", symbolName: "figure.run"),
        "hobbies": Entry(title: "Hobbies & Leisure", subtitle: "Words about hobbies and free time.", symbolName: "gamecontroller.fill"),
        "entertainment": Entry(title: "Entertainment", subtitle: "Words about movies, music, and media.", symbolName: "tv.fill"),
        "fashion": Entry(title: "Clothing & Style", subtitle: "Words about clothing and fashion.", symbolName: "tshirt.fill"),
        "time": Entry(title: "Time & Planning", subtitle: "Words about time, schedules, and plans.", symbolName: "clock.fill"),
        "law": Entry(title: "Law & Society", subtitle: "Words about laws and society.", symbolName: "building.columns.fill"),
        "communication": Entry(title: "Communication", subtitle: "Words about communication and thoughts.", symbolName: "bubble.left.and.bubble.right.fill"),
    ]

    /// Looks up the Ukrainian copy for a theme id. Falls back to the theme's
    /// own (English) name if it isn't mapped yet, so a new theme in
    /// content.json never breaks the screen — it just shows untranslated
    /// until someone adds an entry above.
    static func entry(for themeId: String, fallbackName: String) -> Entry {
        entries[themeId] ?? Entry(
            title: fallbackName,
            subtitle: "Words about \(fallbackName).",
            symbolName: "square.grid.2x2.fill"
        )
    }
}
