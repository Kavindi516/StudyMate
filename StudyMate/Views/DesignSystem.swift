import SwiftUI

/// Shared look & feel: one gradient, one card style, one set of reusable pieces.
enum Theme {
    static let brandGradient = LinearGradient(
        colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardRadius: CGFloat = 18

    static func priorityColor(_ priority: String?) -> Color {
        switch priority {
        case "High": return .red
        case "Low":  return .green
        default:     return .orange
        }
    }

    static func countdownColor(_ level: StudyMateLogic.CountdownLevel) -> Color {
        switch level {
        case .overdue:     return .red
        case .soon:        return .orange
        case .comfortable: return .green
        }
    }
}

extension View {
    /// Rounded grouped-background card with a soft shadow.
    func softCard(cornerRadius: CGFloat = Theme.cardRadius) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

/// Full-width photo banner with a dark fade at the bottom so overlaid text stays readable.
struct HeroBanner<Content: View>: View {
    let image: String
    let height: CGFloat
    private let content: Content

    init(image: String, height: CGFloat = 170, @ViewBuilder content: () -> Content) {
        self.image = image
        self.height = height
        self.content = content()
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.7)],
                               startPoint: .center, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                content
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
                    .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

/// Small summary tile: tinted icon, big number, caption.
struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14), in: Circle())
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .softCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityIdentifier("stat.\(label.lowercased())")
    }
}

/// Friendly placeholder card; pass `banner` to show one of the study photos instead of an icon.
struct EmptyStateCard: View {
    let title: String
    let systemImage: String
    let message: String
    var banner: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            if let banner {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .overlay {
                        Image(banner).resizable().scaledToFill().accessibilityHidden(true)
                    }
                    .clipped()
            }
            VStack(spacing: 8) {
                if banner == nil {
                    Image(systemName: systemImage)
                        .font(.system(size: 34))
                        .foregroundStyle(Theme.brandGradient)
                        .padding(.bottom, 4)
                }
                Text(title).font(.headline)
                Text(message)
                    .font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, banner == nil ? 44 : 18)
            .padding(.horizontal)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("empty.state")
    }
}

/// Coloured pill, e.g. "High" or "3 days".
struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}
