public struct AnyHashableImmuTableRow: Hashable {
    public let immuTableRow: any (ImmuTableRow & Hashable)

    public init(immuTableRow: any (ImmuTableRow & Hashable)) {
      self.immuTableRow = immuTableRow
    }

    public static func == (lhs: AnyHashableImmuTableRow, rhs: AnyHashableImmuTableRow) -> Bool {
        return AnyHashable(lhs.immuTableRow) == AnyHashable(rhs.immuTableRow)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(immuTableRow))
    }
}
