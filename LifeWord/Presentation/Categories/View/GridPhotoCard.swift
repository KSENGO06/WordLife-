import SwiftUI
import UIKit

/// A photo with a graceful fallback chain, used by both the grid cards and
/// the theme-detail header:
/// 1. `preferredImageName` — a dedicated hero photo, e.g. "theme_home", if one has been added to Assets.
/// 2. `fallbackImageNames` — real photos to try in order (a category can have more than one
///    plausible asset name — content.json's `icon` field doesn't always match the id-based
///    naming convention, e.g. underscores vs hyphens — so we try a couple of candidates).
/// 3. `symbolName` — a soft, accent-tinted SF Symbol so the screen never shows a blank/broken tile.
struct ArtworkFallback: View {
    var preferredImageName: String? = nil
    var fallbackImageNames: [String] = []
    let symbolName: String

    private var resolvedImage: UIImage? {
        if let preferredImageName, let uiImage = UIImage(named: preferredImageName) {
            return uiImage
        }
        for name in fallbackImageNames {
            if let uiImage = UIImage(named: name) {
                return uiImage
            }
        }
        return nil
    }

    var body: some View {
        if let uiImage = resolvedImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .contentShape(Rectangle())
        } else {
            ZStack {
                LinearGradient(
                    colors: [Color.appAccent.opacity(0.16), Color.appAccent.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: symbolName)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Color.appAccent.opacity(0.5))
            }
        }
    }
}

/// The 20 phrasal-verbs categories' cover photos already exist in
/// Assets.xcassets ("theme_phrasal-<suffix>") — hand-shortened names from
/// whoever generated them, not a mechanical transform of the category id,
/// so there's no way to derive them other than a lookup table.
enum PhrasalThemeAsset {
    private static let suffixes: [String: String] = [
        "phrasal-verbs-start-end": "start-end",
        "phrasal-verbs-relationships-conflict": "relationships",
        "phrasal-verbs-work-tasks": "work",
        "phrasal-verbs-movement-travel": "movement",
        "phrasal-verbs-money": "money",
        "phrasal-verbs-emotions-state": "emotions",
        "phrasal-verbs-problem-solving": "problems",
        "phrasal-verbs-health": "health",
        "phrasal-verbs-clothing": "clothing",
        "phrasal-verbs-home-household": "home",
        "phrasal-verbs-learning-information": "learning",
        "phrasal-verbs-technology": "technology",
        "phrasal-verbs-weather": "weather",
        "phrasal-verbs-time-plans": "time",
        "phrasal-verbs-success-failure": "success",
        "phrasal-verbs-storytelling-communication": "storytelling",
        "phrasal-verbs-personal-growth": "personal-growth",
        "phrasal-verbs-food": "food",
        "phrasal-verbs-habits-dependencies": "habits",
        "phrasal-verbs-social-events": "social",
    ]

    static func imageName(for categoryId: String) -> String? {
        suffixes[categoryId].map { "theme_phrasal-\($0)" }
    }
}

/// Content.json's `icon` field doesn't always match the real asset name
/// (hyphen vs underscore typos here and there). Try the stated icon, then
/// the id-based convention, then an underscored variant.
enum ImageAssetResolver {
    static func candidates(for category: Category) -> [String] {
        var names = [category.icon, "theme_\(category.id)", "\(category.id)_scene"]
        let underscored = category.icon.replacingOccurrences(of: "-", with: "_")
        if underscored != category.icon {
            names.append(underscored)
        }
        return names
    }
}

/// A 2-column grid tile: photo, bottom scrim, title + caption, and a small
/// accent-colored arrow badge — the "Категорії" home-grid card style.
struct GridPhotoCard: View {
    let title: String
    let subtitle: String
    var preferredImageName: String? = nil
    var fallbackImageNames: [String] = []
    var symbolName: String = "square.grid.2x2.fill"

    var body: some View {
        ArtworkFallback(
            preferredImageName: preferredImageName,
            fallbackImageNames: fallbackImageNames,
            symbolName: symbolName
        )
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .clipped()
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.black.opacity(0.80), .black.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 96)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(12)
        }
        .overlay(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(Color.appAccent)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// A subcategory row inside a theme-detail screen: thumbnail, title, word
/// count, chevron — a rounded card rather than a plain list separator row.
struct CategoryThumbnailRow: View {
    let title: String
    let subtitle: String
    let category: Category

    var body: some View {
        HStack(spacing: 14) {
            ArtworkFallback(
                fallbackImageNames: ImageAssetResolver.candidates(for: category),
                symbolName: "square.grid.2x2.fill"
            )
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.appBodySmall)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appAccent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
