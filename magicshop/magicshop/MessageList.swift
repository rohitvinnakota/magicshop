import SwiftUI

struct MessageList: View {
    @Binding var messages: [MessageViewModel]
    @State private var isKeyboardShown = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { value in
                ForEach(messages, id: \.id) { message in
                    if isKeyboardShown {
                        if message == messages.last {
                            MessageRow(message: message)
                        }
                    } else {
                        MessageRow(message: message)
                    }
                }
                Spacer()
                    .id("spacer-id")
                    .frame(height: 20)
                .onChange(of: messages.count) { _ in
                    value.scrollTo("spacer-id", anchor: .bottom)
                }
            }
            .padding(.vertical)
        }
        .frame(height: UIScreen.main.bounds.height / 3)
        .refreshable {}
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { notification in
            self.isKeyboardShown = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { notification in
            self.isKeyboardShown = false
        }
    }
}
