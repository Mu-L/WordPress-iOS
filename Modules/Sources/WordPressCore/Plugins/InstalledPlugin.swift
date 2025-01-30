import Foundation
import SwiftUI
import WordPressAPI

public struct InstalledPlugin: Equatable, Hashable, Identifiable, Sendable {
    public var slug: PluginSlug
    public var iconURL: URL?
    public var name: String
    public var version: String
    public var author: String
    public var shortDescription: String
    public var isActive: Bool

    public init(slug: PluginSlug, iconURL: URL?, name: String, version: String, author: String, shortDescription: String, isActive: Bool) {
        self.slug = slug
        self.iconURL = iconURL
        self.name = name
        self.version = version
        self.author = author
        self.shortDescription = shortDescription
        self.isActive = isActive
    }

    public init(plugin: PluginWithViewContext) {
        self.slug = plugin.plugin
        iconURL = nil
        name = plugin.name
        version = plugin.version
        author = plugin.author
        shortDescription = plugin.description.raw
        isActive = plugin.status == .active || plugin.status == .networkActive
    }

    public var id: String {
        slug.slug
    }

    public var possibleWpOrgDirectorySlug: PluginWpOrgDirectorySlug? {
        guard let maybeWpOrgSlug = slug.slug.split(separator: "/").first else { return nil }
        return .init(slug: String(maybeWpOrgSlug))
    }

    public func renderedDescription(fontSize: CGFloat) -> AttributedString? {
        guard var data = shortDescription.data(using: .utf8) else {
            return nil
        }

        // We want to use the system font, instead of the default "Times New Roman" font in the rendered HTML.
        // Using `.defaultAttributes: [.font: systemFont(...)]` in the `NSAttributedString` initialiser below doesn't
        // work. Using a CSS style here as a workaround.
        data.append(contentsOf: "<style> body { font-family: -apple-system; font-size: \(fontSize)px; } </style>".data(using: .utf8)!)

        do {
            let string = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                    .sourceTextScaling: NSTextScalingType.iOS,
                ],
                documentAttributes: nil
            )
            return try AttributedString(string, including: \.uiKit)
        } catch {
            return nil
        }
    }
}
