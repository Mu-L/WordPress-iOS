import Foundation
import AsyncImageKit
import WordPressAPI
import WordPressCore

struct PluginIconResolver: ImageURLResolver {
    let slug: PluginWpOrgDirectorySlug?
    weak var service: PluginServiceProtocol?

    var id: String? {
        slug?.slug
    }

    func imageURL() async -> URL? {
        guard let slug else { return nil }

        return await service?.resolveIconURL(of: slug)
    }
}
