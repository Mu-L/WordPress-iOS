import Foundation
import SwiftUI
import AsyncImageKit
import WordPressCore
import WordPressAPI

struct PluginDetailsView: View {

    private static let iconSize: CGFloat = 96

    @ScaledMetric(relativeTo: .body) var descriptionFontSize: CGFloat = 16

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

    var site: JetpackSiteRef
    var plugin: InstalledPlugin
    var iconResolver: PluginIconResolver

    var body: some View {
        ScrollView {
            CachedAsyncImage(urlResolver: iconResolver) { image in
                image.resizable()
            } placeholder: {
                Image("site-menu-plugins")
                    .resizable()
            }
            .frame(width: Self.iconSize, height: Self.iconSize)

            Text(name)
                .font(.title)
                .foregroundStyle(.primary)

            Text(Strings.version(version))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !author.isEmpty {
                Text(Strings.author(author))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Group {
                if shortDescription.isEmpty {
                    Text(Strings.noDescriptionAvailable)
                        .font(.system(size: descriptionFontSize).italic())
                } else if let html = plugin.renderedDescription(fontSize: descriptionFontSize) {
                    Text(html)
                } else {
                    Text(shortDescription)
                        .font(.system(size: descriptionFontSize))
                }
            }
            .padding(.top, 4)

            Spacer()

            NavigationLink {
                if let slug = plugin.possibleWpOrgDirectorySlug {
                    PluginDirectoryPluginDetailView(site: site, slug: slug)
                        .navigationTitle(plugin.name)
                }
            } label: {
                Label("View on WordPress.org", systemImage: "chevron.right")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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

struct PluginDirectoryPluginDetailView: UIViewControllerRepresentable {
    var site: JetpackSiteRef
    var slug: PluginWpOrgDirectorySlug

    func makeUIViewController(context: Context) -> some UIViewController {
        PluginViewController(slug: slug.slug, site: site)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Do nothing.
    }
}
