import SwiftUI

public protocol ImageURLResolver: Sendable, Identifiable {
    func imageURL() async -> URL?
}

/// Asynchronous Image View that replicates the public API of `SwiftUI.AsyncImage`.
/// It uses `ImageDownloader` to fetch and cache the images.
public struct CachedAsyncImage<Content, Resolver: ImageURLResolver>: View where Content: View {
    @State private var phase: AsyncImagePhase = .empty
    private let urlResolver: Resolver
    private let content: (AsyncImagePhase) -> Content
    private let imageDownloader: ImageDownloader
    private let host: MediaHostProtocol?

    public var body: some View {
        content(phase)
            .task(id: urlResolver.id) { await fetchImage() }
    }

    // MARK: - Initializers

    /// Initializes an image without any customization.
    /// Provides a plain color as placeholder
    public init(url: URL?) where Content == _ConditionalContent<Image, Color>, Resolver == StaticImageURLResolver {
        self.init(urlResolver: .init(url: url))
    }

    public init(urlResolver: Resolver) where Content == _ConditionalContent<Image, Color> {
        self.init(urlResolver: urlResolver) { phase in
            if let image = phase.image {
                image
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
    }

    /// Allows content customization and providing a placeholder that will be shown
    /// until the image download is finalized.
    public init<I, P>(
        url: URL?,
        host: MediaHostProtocol? = nil,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View, Resolver == StaticImageURLResolver {
        self.init(urlResolver: .init(url: url), host: host, content: content, placeholder: placeholder)
    }

    public init<I, P>(
        urlResolver: Resolver,
        host: MediaHostProtocol? = nil,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(urlResolver: urlResolver, host: host) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    public init(
        url: URL?,
        host: MediaHostProtocol? = nil,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) where Resolver == StaticImageURLResolver {
        self.init(urlResolver: .init(url: url), host: host, imageDownloader: imageDownloader, content: content)
    }

    public init(
        urlResolver: Resolver,
        host: MediaHostProtocol? = nil,
        imageDownloader: ImageDownloader = .shared,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.urlResolver = urlResolver
        self.host = host
        self.imageDownloader = imageDownloader
        self.content = content
    }

    // MARK: - Helpers

    private func fetchImage() async {
        do {
            guard let url = await urlResolver.imageURL() else {
                phase = .empty
                return
            }
            if let image = imageDownloader.cachedImage(for: url) {
                phase = .success(Image(uiImage: image))
            } else {
                let image: UIImage
                if let host {
                    image = try await imageDownloader.image(from: url, host: host)
                } else {
                    image = try await imageDownloader.image(from: url)
                }
                phase = .success(Image(uiImage: image))
            }
        } catch {
            phase = .failure(error)
        }
    }
}

public struct StaticImageURLResolver: ImageURLResolver {
    let url: URL?

    public var id: URL? {
        url
    }

    public func imageURL() async -> URL? {
        url
    }
}
