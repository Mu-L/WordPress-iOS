import SwiftUI
import WordPressUI

protocol ReaderDetailHeaderViewDelegate: AnyObject {
    func didTapBlogName()
    func didTapHeaderAvatar()
    func didTapFollowButton(completion: @escaping () -> Void)
    func didSelectTopic(_ topic: String)
    func didTapLikes()
    func didTapComments()
    func didTapFeaturedImage()
}

final class ReaderDetailHeaderHostingView: UIView {
    weak var delegate: ReaderDetailHeaderViewDelegate? {
        didSet {
            viewModel.headerDelegate = delegate
        }
    }

    var displaySetting: ReaderDisplaySetting = .standard {
        didSet {
            viewModel.displaySetting = displaySetting
            Task { @MainActor in
                refreshContainerLayout()
            }
        }
    }

    private var postObjectID: TaggedManagedObjectID<ReaderPost>? = nil

    // TODO: Populate this with values from the ReaderPost.
    private lazy var viewModel: ReaderDetailHeaderViewModel = {
        $0.topicDelegate = self
        return $0
    }(ReaderDetailHeaderViewModel(displaySetting: displaySetting))

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        setupView()
    }

    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        let headerView = ReaderDetailHeaderView(viewModel: viewModel) { [weak self] in
            self?.refreshContainerLayout()
        }

        let view = UIView.embedSwiftUIView(headerView)
        addSubview(view)
        pinSubviewToAllEdges(view)
    }

    func refreshContainerLayout() {
        guard let swiftUIView = subviews.first else {
            return
        }

        DispatchQueue.main.async {
            swiftUIView.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
        }
    }
}

// MARK: ReaderDetailHeader

extension ReaderDetailHeaderHostingView {
    func configure(for post: ReaderPost) {
        viewModel.configure(with: TaggedManagedObjectID(post),
                            completion: refreshContainerLayout)
    }

    func refreshFollowButton() {
        viewModel.refreshFollowState()
    }
}

// MARK: ReaderTopicCollectionViewCoordinatorDelegate

extension ReaderDetailHeaderHostingView: ReaderTopicCollectionViewCoordinatorDelegate {
    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didSelectTopic topic: String) {
        delegate?.didSelectTopic(topic)
    }

    func coordinator(_ coordinator: ReaderTopicCollectionViewCoordinator, didChangeState: ReaderTopicCollectionViewState) {
        // no op
    }
}

// MARK: - SwiftUI View Model

class ReaderDetailHeaderViewModel: ObservableObject {
    private let coreDataStack: CoreDataStackSwift
    private var postObjectID: TaggedManagedObjectID<ReaderPost>? = nil

    weak var headerDelegate: ReaderDetailHeaderViewDelegate?
    weak var topicDelegate: ReaderTopicCollectionViewCoordinatorDelegate?

    // Follow/Unfollow states
    @Published var isFollowingSite = false
    @Published var isFollowButtonInteractive = true

    @Published var siteIconURL: URL?
    @Published var authorAvatarURL: URL?
    @Published var authorName = ""
    @Published var relativePostTime = ""
    @Published var siteName = String()
    @Published var postTitle: String? // post title can be empty.
    @Published var likeCount: Int?
    @Published var commentCount: Int?
    @Published var tags: [String] = []
    @Published var featuredImageURL: URL?

    @Published var showsAuthorName: Bool = true

    @Published var displaySetting: ReaderDisplaySetting

    var likeCountString: String? {
        guard let count = likeCount, count > 0 else {
            return nil
        }
        return WPStyleGuide.likeCountForDisplay(count)
    }

    var commentCountString: String? {
        guard let count = commentCount, count > 0 else {
            return nil
        }
        return WPStyleGuide.commentCountForDisplay(count)
    }

    init(displaySetting: ReaderDisplaySetting, coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        self.displaySetting = displaySetting
        self.coreDataStack = coreDataStack
    }

    func configure(with objectID: TaggedManagedObjectID<ReaderPost>, completion: (() -> Void)?) {
        postObjectID = objectID
        coreDataStack.performQuery { [weak self] context -> Void in
            guard let self,
                  let post = try? context.existingObject(with: objectID) else {
                return
            }

            self.isFollowingSite = post.isFollowing

            self.siteIconURL = post.getSiteIconURL(size: Int(ReaderDetailHeaderView.Constants.siteIconLength))
            self.authorAvatarURL = post.avatarURLForDisplay() ?? nil

            if let authorName = post.authorForDisplay(), !authorName.isEmpty {
                self.authorName = authorName
            }

            if let relativePostTime = post.dateForDisplay()?.toMediumString() {
                self.relativePostTime = relativePostTime
            }

            if let siteName = post.blogNameForDisplay(), !siteName.isEmpty {
                self.siteName = siteName
            }

            // hide the author name if it exactly matches the site name.
            // context: https://github.com/wordpress-mobile/WordPress-iOS/pull/21674#issuecomment-1747202728
            self.showsAuthorName = self.authorName != self.siteName && !self.authorName.isEmpty

            self.postTitle = post.titleForDisplay() ?? nil
            self.likeCount = post.likeCount?.intValue
            self.commentCount = post.commentCount?.intValue
            self.tags = post.tagsForDisplay() ?? []
            self.featuredImageURL = getFeaturedImageURL(for: post)
        }

        DispatchQueue.main.async {
            completion?()
        }
    }

    func getFeaturedImageURL(for post: ReaderPost) -> URL? {
        guard let imageURL = URL(string: post.featuredImage) else {
            return nil
        }
        guard !post.contentIncludesFeaturedImage() else {
            return nil
        }
        return imageURL
    }

    func refreshFollowState() {
        guard let postObjectID else {
            return
        }

        isFollowingSite = coreDataStack.performQuery { context in
            guard let post = try? context.existingObject(with: postObjectID) else {
                return false
            }
            return post.isFollowing
        }
    }

    func didTapAuthorSection() {
        headerDelegate?.didTapBlogName()
    }

    func didTapFollowButton() {
        guard let headerDelegate else {
            return
        }

        isFollowButtonInteractive = false
        isFollowingSite.toggle()

        headerDelegate.didTapFollowButton { [weak self] in
            self?.isFollowButtonInteractive = true
        }
    }

    func didTapLikes() {
        headerDelegate?.didTapLikes()
    }

    func didTapComments() {
        headerDelegate?.didTapComments()
    }
}

// MARK: - SwiftUI

/// The updated header version for Reader Details.
struct ReaderDetailHeaderView: View {

    @Environment(\.layoutDirection) var direction
    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var viewModel: ReaderDetailHeaderViewModel

    /// Used for the inward border. We want the color to be inverted, such that the avatar can "preserve" its shape
    /// when the image has low or almost no contrast with the background (imagine white avatar on white background).
    var avatarInnerBorderColor: UIColor {
        let color = viewModel.displaySetting.color.background
        return colorScheme == .light ? color.darkVariant() : color.lightVariant()
    }

    var primaryTextColor: UIColor {
        viewModel.displaySetting.color.foreground
    }

    var innerBorderOpacity: CGFloat {
        return colorScheme == .light ? 0.1 : 0.2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            headerRow
            if let postTitle = viewModel.postTitle {
                Text(postTitle)
                    .font(Font(viewModel.displaySetting.font(with: .title1, weight: .bold)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(nil)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true) // prevents the title from being truncated.
            }
            if let imageURL = viewModel.featuredImageURL {
                coverView(with: imageURL)
            }
            if viewModel.likeCountString != nil || viewModel.commentCountString != nil {
                postCounts
            }
            if !viewModel.tags.isEmpty {
                tagsView
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
    }

    var headerRow: some View {
        HStack(spacing: 8.0) {
            authorStack
            Spacer()
            ReaderFollowButton(isFollowing: viewModel.isFollowingSite,
                               isEnabled: viewModel.isFollowButtonInteractive,
                               size: .compact,
                               displaySetting: viewModel.displaySetting) {
                viewModel.didTapFollowButton()
            }
        }
    }

    func coverView(with imageURL: URL) -> some View {
        // Rendering image as an overlay to prevent it from affecting the layout.
        Color.clear.overlay {
            CachedAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.secondarySystemBackground)
            }
        }
        .aspectRatio(1.0 / ReaderPostCell.coverAspectRatio, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            viewModel.headerDelegate?.didTapFeaturedImage()
        }
    }

    var authorStack: some View {
        HStack(spacing: 8.0) {
            if let siteIconURL = viewModel.siteIconURL,
               let avatarURL = viewModel.authorAvatarURL {
                avatarView(with: siteIconURL, avatarURL: avatarURL)
            }
            VStack(alignment: .leading, spacing: 4.0) {
                Text(viewModel.siteName)
                    .font(Font(viewModel.displaySetting.font(with: .callout, weight: .semibold)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(1)
                authorAndTimestampView
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits([.isButton])
        .accessibilityHint(Constants.authorStackAccessibilityHint)
        .onTapGesture {
            viewModel.didTapAuthorSection()
        }
    }

    @ViewBuilder
    func avatarView(with siteIconURL: URL, avatarURL: URL) -> some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: siteIconURL) { image in
                image.resizable()
            } placeholder: {
                Image("post-blavatar-default").resizable()
            }
            .frame(width: Constants.siteIconLength, height: Constants.siteIconLength)
            .clipShape(Circle())
            .overlay {
                // adds an inward border with low opacity to preserve the avatar's shape.
                Circle()
                    .strokeBorder(Color(uiColor: avatarInnerBorderColor), lineWidth: 0.5)
                    .opacity(innerBorderOpacity)
            }

            AsyncImage(url: avatarURL) { image in
                image.resizable()
            } placeholder: {
                Image("blavatar-default").resizable()
            }
            .frame(width: Constants.authorImageLength, height: Constants.authorImageLength)
            .clipShape(Circle())
            .overlay {
                // adds an inward border with low opacity to preserve the avatar's shape.
                Circle()
                    .strokeBorder(Color(uiColor: avatarInnerBorderColor), lineWidth: 0.5)
                    .opacity(innerBorderOpacity)
            }
            .background {
                // adds a border between the the author avatar and the site icon.
                Circle()
                    .stroke(Color(uiColor: viewModel.displaySetting.color.background), lineWidth: 1.0)
            }
            .offset(x: 2.0, y: 2.0)
        }
    }

    var postCounts: some View {
        HStack(spacing: 0) {
            if let likeCount = viewModel.likeCountString {
                Group {
                    Button(action: viewModel.didTapLikes) {
                        Text(likeCount)
                    }
                    if viewModel.commentCountString != nil {
                        Text(" • ")
                    }
                }
            }
            if let commentCount = viewModel.commentCountString {
                Button(action: viewModel.didTapComments) {
                    Text(commentCount)
                }
            }
        }
        .font(Font(viewModel.displaySetting.font(with: .footnote)))
        .foregroundStyle(Color(viewModel.displaySetting.color.secondaryForeground))
    }

    var tagsView: some View {
        ReaderDetailTagsWrapperView(topics: viewModel.tags, displaySetting: viewModel.displaySetting, delegate: viewModel.topicDelegate)
    }

    var authorAndTimestampView: some View {
        HStack(spacing: 0) {
            if viewModel.showsAuthorName {
                Text(viewModel.authorName)
                    .font(Font(viewModel.displaySetting.font(with: .footnote)))
                    .foregroundStyle(Color(primaryTextColor))
                    .lineLimit(1)

                Text(" • ")
                    .font(Font(viewModel.displaySetting.font(with: .footnote)))
                    .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
                    .lineLimit(1)
                    .layoutPriority(1)
            }

            timestampText
                .lineLimit(1)
                .layoutPriority(1)

            Spacer()
        }
        .accessibilityElement()
        .accessibilityLabel(authorAccessibilityLabel)
    }

    var timestampText: Text {
        Text(viewModel.relativePostTime)
            .font(Font(viewModel.displaySetting.font(with: .footnote)))
            .foregroundColor(Color(viewModel.displaySetting.color.secondaryForeground))
    }
}

// MARK: Private Helpers

fileprivate extension ReaderDetailHeaderView {

    struct Constants {
        static let siteIconLength: CGFloat = 40.0
        static let authorImageLength: CGFloat = 20.0

        static let authorStackAccessibilityHint = NSLocalizedString(
            "reader.detail.header.authorInfo.a11y.hint",
            value: "Views posts from the site",
            comment: "Accessibility hint to inform that the author section can be tapped to see posts from the site."
        )
    }

    var authorAccessibilityLabel: String {
        var labels = [viewModel.relativePostTime]

        if viewModel.showsAuthorName {
            labels.insert(viewModel.authorName, at: .zero)
        }

        return labels.joined(separator: ", ")
    }
}

// MARK: - TopicCollectionView UIViewRepresentable Wrapper

fileprivate struct ReaderDetailTagsWrapperView: UIViewRepresentable {
    private let topics: [String]
    private let displaySetting: ReaderDisplaySetting
    private weak var delegate: ReaderTopicCollectionViewCoordinatorDelegate?

    init(topics: [String], displaySetting: ReaderDisplaySetting, delegate: ReaderTopicCollectionViewCoordinatorDelegate?) {
        self.topics = topics
        self.displaySetting = displaySetting
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> UICollectionView {
        let view = TopicsCollectionView(frame: .zero, collectionViewLayout: ReaderInterestsCollectionViewFlowLayout())
        view.topics = topics
        view.topicDelegate = delegate

        if ReaderDisplaySetting.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        // ensure that the collection view hugs its content.
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        if let view = uiView as? TopicsCollectionView,
           ReaderDisplaySetting.customizationEnabled {
            view.coordinator?.displaySetting = displaySetting
        }

        uiView.reloadData()
        uiView.layoutIfNeeded()
    }
}
