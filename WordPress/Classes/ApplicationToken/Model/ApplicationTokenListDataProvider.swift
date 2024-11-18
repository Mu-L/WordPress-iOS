import Foundation

public protocol ApplicationTokenListDataProvider {
    func loadApplicationTokens() async throws -> [ApplicationTokenItem]

    func loadApplicationTokens(userId: Int32) async throws -> [ApplicationTokenItem]
}
