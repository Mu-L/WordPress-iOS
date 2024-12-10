import Foundation

public enum Query<T>: Equatable where T: Identifiable, T: Searchable {
    case all
    case id(Set<T.ID>)
    case search(String)
}
