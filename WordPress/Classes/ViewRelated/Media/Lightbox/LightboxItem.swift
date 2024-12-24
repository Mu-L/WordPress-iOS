import Foundation
import WordPressMedia

enum LightboxItem {
    case asset(LightboxAsset)
    case media(Media)
}

struct LightboxAsset {
    let sourceURL: URL
    var host: MediaHost?
}
