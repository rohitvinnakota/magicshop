
import SwiftUI

struct AnimatedButtonsView: View {

@State private var animation1 = false
@State private var animation2 = false
@State private var animation3 = false

var body: some View {
    VStack {
        Button(action: {
            // Perform action for button 1
            self.animation1.toggle()
        }) {
            Text("Button 1")
                .font(.title)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .scaleEffect(animation1 ? 1.5 : 1)
                .animation(.spring())
        }
        Button(action: {
            // Perform action for button 2
            self.animation2.toggle()
        }) {
            Text("Button 2")
                .font(.title)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .clipShape(Capsule())
                .scaleEffect(animation2 ? 1.5 : 1)
                .animation(.spring())
        }
        Button(action: {
            // Perform action for button 3
            self.animation3.toggle()
        }) {
            Text("Button 3")
                .font(.title)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .scaleEffect(animation3 ? 1.5 : 1)
                .animation(.spring())
        }
    }
}
}

struct AnimatedButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedButtonsView()
    }
}
