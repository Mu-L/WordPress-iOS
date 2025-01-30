import Foundation
import SwiftUI
import AsyncImageKit
import WordPressCore

struct PluginListItemView: View {

    private static let iconSize: CGFloat = 44

    @ScaledMetric(relativeTo: .body) var descriptionFontSize: CGFloat = 14

    private var iconURL: URL? {
        plugin.iconURL
    }

    private var name: String {
        plugin.name
    }

    private var version: String {
        plugin.version
    }

    private var author: String {
        plugin.author
    }

    private var shortDescription: String {
        plugin.shortDescription
    }

    private var plugin: InstalledPlugin
    private var iconResolver: PluginIconResolver

    init(plugin: InstalledPlugin, iconResolver: PluginIconResolver) {
        self.plugin = plugin
        self.iconResolver = iconResolver
    }

    var body: some View {
        HStack(alignment: .top) {
            CachedAsyncImage(urlResolver: iconResolver) { image in
                image.resizable()
            } placeholder: {
                Image("site-menu-plugins")
                    .resizable()
            }
            .frame(width: Self.iconSize, height: Self.iconSize)
            .padding(.all, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Group {
                    if shortDescription.isEmpty {
                        Text(Strings.noDescriptionAvailable)
                            .font(.system(size: descriptionFontSize).italic())
                    } else if let html = renderedDescription() {
                        Text(html)
                    } else {
                        Text(shortDescription)
                            .font(.system(size: descriptionFontSize))
                    }
                }
                .lineLimit(3)
            }
        }
    }

    func renderedDescription() -> AttributedString? {
        guard var data = shortDescription.data(using: .utf8) else {
            return nil
        }

        // We want to use the system font, instead of the default "Times New Roman" font in the rendered HTML.
        // Using `.defaultAttributes: [.font: systemFont(...)]` in the `NSAttributedString` initialiser below doesn't
        // work. Using a CSS style here as a workaround.
        data.append(contentsOf: "<style> body { font-family: -apple-system; font-size: \(descriptionFontSize)px; } </style>".data(using: .utf8)!)

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
            DDLogError("Failed to parse HTML: \(error)")
            return nil
        }
    }

    private enum Strings {
        static func author(_ author: String) -> String {
            let format = NSLocalizedString("site.plugins.list.item.author", value: "By %@", comment: "The plugin author displayed in the plugins list. The first argument is plugin author name")
            return String(format: format, author)
        }

        static func version(_ version: String) -> String {
            let format = NSLocalizedString("site.plugins.list.item.author", value: "Version: %@", comment: "The plugin version displayed in the plugins list. The first argument is plugin version")
            return String(format: format, version)
        }

        static let noDescriptionAvailable: String = NSLocalizedString("site.plugins.list.item.noDescriptionAvailable", value: "The plugin author did not provide a description for this plugin.", comment: "The message displayed when a plugin has no description")
    }
}
