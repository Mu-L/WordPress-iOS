/// ImmuTableSection represents the view model for a table view section.
///
/// A section has an optional header and footer text, and zero or more rows.
/// - seealso: ImmuTableRow
///
public struct ImmuTableSection {
    public let headerText: String?
    public let rows: [ImmuTableRow]
    public let footerText: String?

    /// Initializes a ImmuTableSection with the given rows and optionally header and footer text
    public init(headerText: String? = nil, rows: [ImmuTableRow], footerText: String? = nil) {
        self.headerText = headerText
        self.rows = rows
        self.footerText = footerText
    }
}
