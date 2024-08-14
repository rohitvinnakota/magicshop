import SwiftUI
import Network

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var currentTab = 0
    @ObservedObject var feedManager = FeedManager()

    init() {
        UITabBar.appearance().barTintColor = UIColor(named: "Secondary")
    }

    var body: some View {
        VStack {
            TabView(selection: $currentTab) {
                MarketView()
                    .environmentObject(sessionManager)
                    .environmentObject(feedManager)
                    .tabItem {
                        Image(systemName: "cart")
                        Text("Market")
                    }
                   .tag(0)
                   .onAppear() {
                      self.currentTab = 0
                   }
                AVPermissionsView()
                    .tabItem {
                        Image(systemName: "plus.square")
                        Text("Go live")
                    }
                    .tag(1)
                    .onAppear() {
                       self.currentTab = 1
                    }
                    .environmentObject(sessionManager)
                SettingsView()
                    .environmentObject(sessionManager)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
                    .onAppear() {
                        self.currentTab = 2
                    }
            }
            .accentColor(Constants.crayolaRedColor)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionManager())
    }
}
