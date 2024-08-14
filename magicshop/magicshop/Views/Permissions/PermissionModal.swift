import SwiftUI

struct PermissionModal: View {
    var title: String
    var description: String
    @Binding var isOn: Bool
    var action: () -> Void

    var body: some View {
        HStack(spacing: 23) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isOn ? Color.clear : Color.gray, lineWidth: 3)
                    .frame(width: 32, height: 32)
                    .background(isOn ? Color.yellow : Color.clear)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .padding(.top, 2)

                if isOn {
                    Image(systemName: "checkmark")
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundColor(Color.gray)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 20)
        .onTapGesture {
            action()
        }
    }
}
