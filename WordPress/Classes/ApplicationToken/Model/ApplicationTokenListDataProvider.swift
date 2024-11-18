import Foundation

public protocol ApplicationTokenListDataProvider {
    func loadApplicationTokens(userId: Int32) async throws -> [ApplicationTokenItem]
}

class StaticTokenProvider: ApplicationTokenListDataProvider {

    private let result: Result<[ApplicationTokenItem], Error>

    init(tokens: Result<[ApplicationTokenItem], Error>) {
        self.result = tokens
    }

    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        try result.get()
    }

    func loadApplicationTokens(userId: Int32) async throws -> [ApplicationTokenItem] {
        try result.get()
    }

}
