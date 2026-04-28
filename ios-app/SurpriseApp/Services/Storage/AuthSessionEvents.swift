import Foundation

extension Notification.Name {
    static let authSessionExpired = Notification.Name("authSessionExpired")
    static let tapBarShouldHide   = Notification.Name("tapBarShouldHide")
    static let tapBarShouldShow   = Notification.Name("tapBarShouldShow")
    static let openFeedTab        = Notification.Name("openFeedTab")
    static let accountDeleted        = Notification.Name("accountDeleted")
    static let scrollFeedToTop       = Notification.Name("scrollFeedToTop")
    static let scrollFavoritesToTop  = Notification.Name("scrollFavoritesToTop")
}
