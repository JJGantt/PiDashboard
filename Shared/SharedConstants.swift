import Foundation

enum PiConstants {
    static var localBaseURL: String {
        let host = Bundle.main.infoDictionary?["PILocalHost"] as? String ?? ""
        return "http://\(host)"
    }
    static var tailscaleBaseURL: String {
        let host = Bundle.main.infoDictionary?["PITailscaleHost"] as? String ?? ""
        return "http://\(host)"
    }
    static let appGroupID = "group.com.jaredgantt.tvdashboard"
    static let urlScheme = "tvdashboard"
    static let dashboardCacheKey = "cachedDashboard"
    static let refreshInterval: TimeInterval = 60
    static let requestTimeout: TimeInterval = 10

    // Coding mode endpoints
    static let codingMessagePath = "/tv/coding/message"
    static let codingClearPath = "/tv/coding/clear"
    static let codingHistoryPath = "/tv/coding/history"
    static let codingSessionSummariesPath = "/tv/coding/session-summaries"
}
