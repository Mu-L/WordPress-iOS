import WordPressShared

/// A no-op mock implementation of the KeyValueDatabase protocol
class NullMockUserDefaults: KeyValueDatabase {
    func object(forKey defaultName: String) -> Any? {
        return nil
    }

    func set(_ value: Any?, forKey defaultName: String) {}

    func removeObject(forKey defaultName: String) {}
}
