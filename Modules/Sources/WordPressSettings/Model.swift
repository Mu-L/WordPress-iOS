import Foundation

struct SettingsSuite: Codable {
    enum Children: Codable {
        case page(SettingPage)
        case group(SettingGroup)
        case setting(Setting)
    }

    let title: String
    let icon: String
    let color: String
    let settings: [Children]
}

struct SettingPage: Codable {
    enum Children: Codable {
        case group(SettingGroup)
        case setting(Setting)
    }

    let title: String
    let description: String
    let settings: [Children]
}

struct SettingGroup: Codable {
    let title: String
    let headerText: String?
    let footerText: String?
    let settings: [Setting]
}

struct Setting: Codable {

    enum SettingValue: Codable {
        case bool(Bool)
        case string(String)
        case color(String)
        case date(Date)
        case set // A set of allowed values
        case uuid(UUID)
        case postId(Int)
        case mediaId(Int)
        case userId(Int)
        case role(String)
    }

    let type: String

    let key: String

    let value: SettingValue

    let description: String?

    let allowedValues: [SettingValue]
}
