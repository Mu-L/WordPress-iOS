import SwiftUI
import DesignSystem
import WordPressUI
import WordPressAPI

extension WpApiError {
    var errorMessage: String {
        switch self {
        case .InvalidHttpStatusCode, .SiteUrlParsingError, .UnknownError:
            return NSLocalizedString("Something went wrong", comment: "A generic error message")
        case let .RequestExecutionFailed(_, reason):
            return reason
        case .ResponseParsingError:
            return NSLocalizedString("generic.error.unparsableResponse", value: "Your site sent a response that the app could not parse", comment: "Error message when failing to parse API responses")
        case let .WpError(_, errorMessage, _, _):
            let format = NSLocalizedString("generic.error.rest-api-error", value: "Your site sent an error response: %@", comment: "Error message format when REST API returns an error response. The first argument is error message.")
            return String(format: format, errorMessage)
        }
    }
}
