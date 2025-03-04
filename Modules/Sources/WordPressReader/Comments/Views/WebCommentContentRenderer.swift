import WebKit
import WordPressShared
import WordPressUI
import Combine

/// Renders the comment body with a web view. Provides the best visual experience but has the highest performance cost.
@MainActor
public final class WebCommentContentRenderer: NSObject, CommentContentRenderer {
    // MARK: Properties

    public weak var delegate: CommentContentRendererDelegate?

    public var view: UIView { webView }

    private let webView = WKWebView(frame: .zero, configuration: {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        return configuration
    }())

    /// It can't be changed at the moment, but this capability was included from the
    /// start, and this implementation continues supporting it.
    private var displaySetting = ReaderDisplaySettings.standard

    /// - warning: This has to be configured _before_ you render.
    public var tintColor: UIColor {
        get { webView.tintColor }
        set {
            webView.tintColor = newValue
            cachedHead = nil
        }
    }

    private var cachedHead: String?
    private var comment: String?
    private var lastReloadDate: Date?
    private var isReloadNeeded = false

    private var renderID: UUID?
    private var previousWebViewContentSize: CGSize?
    private var previousReportedContentHeight: CGFloat?
    private var isHeightUpdateNeeded = false
    private var isUpdatingHeight = false

    private var cancellables: [AnyCancellable] = []

        /// A shared web view context with resources that can be reused across
    /// mutliple web view instances.
    @MainActor
    public final class Context {
        let processPool = WKProcessPool()

        public init() {}
    }

    // MARK: Methods

    public required override convenience init() {
        self.init(context: .init())
    }

    public init(context: Context) {
        super.init()

        webView.configuration.processPool = context.processPool

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        webView.backgroundColor = .clear
        webView.isOpaque = false // gets rid of the white flash upon content load in dark mode.
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.backgroundColor = .clear

        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public func render(comment: String) {
        self.comment = comment

        actuallyRender(comment: comment)
        let renderID = UUID()
        self.renderID = renderID

        webView.scrollView.publisher(for: \.contentSize, options: [.new]).sink { [weak self] in
            self?.didChangeContentSize($0, renderID: renderID)
        }.store(in: &cancellables)
    }

    private func actuallyRender(comment: String) {
        webView.loadHTMLString(formattedHTMLString(for: comment), baseURL: nil)
    }

    public func prepareForReuse() {
        renderID = nil // Make sure previous callbacks are not calls/executed
        comment = nil
        isUpdatingHeight = false
        isHeightUpdateNeeded = false
        previousWebViewContentSize = nil
        previousReportedContentHeight = nil
        cancellables = []
        webView.stopLoading()
    }

    @objc private func applicationWillEnterForeground() {
        reloadIfNeeded()
    }

    private func reloadIfNeeded() {
        guard isReloadNeeded, Date.now.timeIntervalSince((lastReloadDate ?? .distantPast)) > 8, let comment else {
            return
        }
        isReloadNeeded = false
        lastReloadDate = Date()
        actuallyRender(comment: comment)
    }

    // MARK: - Content Size

    private func didChangeContentSize(_ size: CGSize, renderID: UUID) {
        guard renderID == self.renderID else { return } // Was reused

        guard previousWebViewContentSize != size else { return }
        previousWebViewContentSize = size
        setNeedsHeightUpdate()
    }

    private func setNeedsHeightUpdate() {
        isHeightUpdateNeeded = true
        updateHeightIfNeeded()
    }

    private func updateHeightIfNeeded() {
        guard let renderID else { return }

        guard isHeightUpdateNeeded && !isUpdatingHeight else { return }
        isUpdatingHeight = true
        isHeightUpdateNeeded = false

        // This is more accurate than WKWebView that has a minimum preferred height
        // settings that is sometimes larger than the actual `s`crollHeight.
        webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] height, _ in
            guard let height = height as? CGFloat else { return }
            self?.didUpdateHeight(height, for: renderID)
        }
    }

    private func didUpdateHeight(_ height: CGFloat, for renderID: UUID) { // for current comment
        guard renderID == self.renderID, let comment else { return }  // Was reused

        isUpdatingHeight = false
        if previousReportedContentHeight != height {
            previousReportedContentHeight = height
            delegate?.renderer(self, asyncRenderCompletedWithHeight: height, comment: comment)
        }
        updateHeightIfNeeded()
    }
}

// MARK: - WKNavigationDelegate

extension WebCommentContentRenderer: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard renderID != nil else { return }
        setNeedsHeightUpdate()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        switch navigationAction.navigationType {
        case .other:
            // allow local file requests.
            return .allow
        default:
            guard let destinationURL = navigationAction.request.url else {
                return .allow
            }
            self.delegate?.renderer(self, interactedWithURL: destinationURL)
            return .cancel
        }
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isReloadNeeded = true
        if UIApplication.shared.applicationState == .active {
            reloadIfNeeded()
        }
    }
}

private extension WebCommentContentRenderer {
    /// Returns a formatted HTML string by loading the template for rich comment.
    ///
    /// The method will try to return cached content if possible, by detecting whether the content matches the previous content.
    /// If it's different (e.g. due to edits), it will reprocess the HTML string.
    ///
    /// - Parameter content: The content value from the `Comment` object.
    /// - Returns: Formatted HTML string to be displayed in the web view.
    ///
    func formattedHTMLString(for comment: String) -> String {
        // remove empty HTML elements from the `content`, as the content often contains empty paragraph elements which adds unnecessary padding/margin.
        // `rawContent` does not have this problem, but it's not used because `rawContent` gets rid of links (<a> tags) for mentions.
        let comment = comment
            .replacingOccurrences(of: Self.emptyElementRegexPattern, with: "", options: [.regularExpression])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        <html dir="auto">
        \(makeHead())
        <body>
            \(comment)
        </body>
        </html>
        """
    }

    static let emptyElementRegexPattern = "<[a-z]+>(<!-- [a-zA-Z0-9\\/: \"{}\\-\\.,\\?=\\[\\]]+ -->)+<\\/[a-z]+>"

    /// Returns HTML page <head> with the preconfigured styles and scripts.
    private func makeHead() -> String {
        if let cachedHead {
            return cachedHead
        }
        let head = actuallyMakeHead()
        cachedHead = head
        return head
    }

    private func actuallyMakeHead() -> String {
        let meta = "width=device-width,initial-scale=\(displaySetting.size.scale),maximum-scale=\(displaySetting.size.scale),user-scalable=no,shrink-to-fit=no"
        let styles = displaySetting.makeStyles(tintColor: webView.tintColor)
        return String(format: Self.headTemplate, meta, styles)
    }

    private static let headTemplate: String = {
        guard let fileURL = Bundle.module.url(forResource: "gutenbergCommentHeadTemplate", withExtension: "html"),
              let string = try? String(contentsOf: fileURL) else {
            assertionFailure("template missing")
            return ""
        }
        return string
    }()
}
