import Foundation

@objc
public class ReachabilityUtils: NSObject {

    @objc
    public static func isInternetReachable() -> Bool {
        (UIApplication.shared.delegate as? NetworkConnectionAvailabilityGetting)?.connectionAvailable ?? false
    }

    @objc
    public static func showAlertNoInternetConnection() {
        ReachabilityAlert(retryBlock: nil).show()
    }

    @objc
    public static func showAlertNoInternetConnection(retryBlock: (() -> Void)? = nil) {
        ReachabilityAlert(retryBlock: retryBlock).show()
    }

    @objc
    public static func noConnectionMessage() -> String {
        NSLocalizedString(
            "reachability-utils.alert.utils",
            value: "The internet connection appears to be offline.",
            comment: "Message of error prompt shown when no internet connection is available"
        )
    }

    @objc
    public static func alertIsShowing() -> Bool {
        currentReachabilityAlert != nil
    }
}
