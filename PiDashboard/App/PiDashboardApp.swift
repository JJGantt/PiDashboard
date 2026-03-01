import SwiftUI

@main
struct PiDashboardApp: App {
    @StateObject private var store = DashboardStore()
    @State private var selectedSection: String?
    @State private var selectedItem: String?

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, selectedSection: $selectedSection, selectedItem: $selectedItem)
                .onAppear {
                    store.startAutoRefresh()
                }
                .onDisappear {
                    store.stopAutoRefresh()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // tvdashboard://section/todo/item/todo-0
        guard url.scheme == PiConstants.urlScheme else { return }
        let components = url.pathComponents.filter { $0 != "/" }
        if components.count >= 2 && components[0] == "section" {
            selectedSection = components[1]
            if components.count >= 4 && components[2] == "item" {
                selectedItem = components[3]
            }
        }
    }
}
