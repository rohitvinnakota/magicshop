import SwiftUI
import AmazonIVSBroadcast

struct BroadcastControlButtonsView: View {
    enum CardPosition: CGFloat {
        case expanded
        case collapsed
        case hidden
    }
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
    
    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @EnvironmentObject var sessionManager: SessionManager

    @ObservedObject private var broadcastManager: BroadcastManager
    
    @GestureState private var dragState = DragState.inactive
    @State var position = CardPosition.collapsed
    @Binding var isControlButtonsPresent: Bool
    
    @State private var hasUserExited = false
    @State private var isSuccessPresent: Bool = false
    @State private var successMessage: String = "" {
        didSet { isSuccessPresent = successMessage != "" }
    }
    @State private var isErrorPresent: Bool = false
    @State private var errorMessage: String = "" {
        didSet { isErrorPresent = errorMessage != "" }
    }
    @State private var isScreenShareAlertPresent: Bool = false
    @State private var isBroadcastPickerViewPresent: Bool = false

    let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.85
    private let narrowScreenRatio = UIScreen.main.bounds.height / UIScreen.main.bounds.width
    private var shareSheet: UIActivityViewController?

    init(broadcastManager: BroadcastManager, isControlButtonsPresent: Binding<Bool>) {
        self.broadcastManager = broadcastManager
        self._isControlButtonsPresent = isControlButtonsPresent
    }

    private func onDragEnded(drag: DragGesture.Value) {
        let isLandscape = verticalSizeClass == .compact
        let dragDirection = isLandscape ? drag.startLocation.x - drag.location.x : drag.startLocation.y - drag.location.y
        let offsetFromTopOfView = cardOffsetX(for: position) +
        (isLandscape ? drag.translation.width : drag.translation.height)
        let expandedPos = cardOffsetX(for: .expanded)
        let hiddenPos = cardOffsetX(for: .hidden)
        let abovePosition: CardPosition
        let belowPosition: CardPosition
        
        if offsetFromTopOfView - expandedPos < hiddenPos - offsetFromTopOfView {
            abovePosition = .expanded
            belowPosition = .collapsed
        } else {
            abovePosition = .collapsed
            belowPosition = .hidden
        }
        
        if dragDirection < 0 {
            position = belowPosition
        } else if dragDirection > 0 {
            position = abovePosition
        }
    }
    
    private func cardOffsetX(for state: CardPosition) -> CGFloat {
        let isLandscape = verticalSizeClass == .compact
        var offset: CGFloat = 0
        let isNarrowScreen = (isLandscape ?
                              floor(UIScreen.main.bounds.width / UIScreen.main.bounds.height) :
                                floor(UIScreen.main.bounds.height / UIScreen.main.bounds.width)) == 2.0
        
        switch state {
        case .expanded:
            offset = isLandscape ?
            UIScreen.main.bounds.width * (isNarrowScreen ? 0.09 : 0) :
            UIScreen.main.bounds.height * (isNarrowScreen ? 0.55 : 0.45)
        case .collapsed:
            offset = isLandscape ?
            UIScreen.main.bounds.width * (isNarrowScreen ? 0.8 * narrowScreenRatio : 0.3) :
            UIScreen.main.bounds.height * (isNarrowScreen ? 0.3 * narrowScreenRatio : 0.6)
        case .hidden:
            offset = (isLandscape ? UIScreen.main.bounds.width : UIScreen.main.bounds.height) * 0.85
        }
        
        if isLandscape {
            return max(offset + dragState.translation.width, UIScreen.main.bounds.width * (isNarrowScreen ? 0.07 : 0))
        } else {
            return max(offset + dragState.translation.height, UIScreen.main.bounds.height * (isNarrowScreen ? 0.4 : 0.3))
        }
    }
    
    
    @ViewBuilder private func streamControlButtons() -> some View {
        Group {
            if broadcastManager.isMuted {
                ControlButton(
                    title: "",
                    action: broadcastManager.mute,
                    icon: "mic.slash.fill",
                    backgroundColor: Constants.error
                )
            } else {
                ControlButton(
                    title: "",
                    action: broadcastManager.mute,
                    icon: "mic.slash.fill",
                    backgroundColor: Constants.backgroundButton
                )
            }
            
            if broadcastManager.cameraIsOn {
                ControlButton(
                    title: "",
                    action: broadcastManager.toggleCamera,
                    icon: "video.slash.fill",
                    backgroundColor: Constants.backgroundButton,
                    disabled: !broadcastManager.canToggleCamera
                )
            } else {
                ControlButton(
                    title: "",
                    action: broadcastManager.toggleCamera,
                    icon: "video.fill",
                    backgroundColor: Constants.error,
                    disabled: !broadcastManager.canToggleCamera
                )
            }

            ControlButton(
                title: "",
                action: broadcastManager.flipCamera,
                icon: "arrow.triangle.2.circlepath.camera.fill",
                disabled: !broadcastManager.canFlipCamera
            )
            
            
            if broadcastManager.sessionIsRunning {
                ControlButton(
                    title: "End stream",
                    action: broadcastManager.toggleBroadcastSession,
                    icon: "multiply",
                    iconColor: .white,
                    iconSize: 30,
                    backgroundColor: .clear,
                    borderColor: Constants.red,
                    disabled: !broadcastManager.canStartSession
                )
            } else {
                ControlButton(
                    title: "Go Live",
                    action: broadcastManager.toggleBroadcastSession,
                    icon: "circle.fill",
                    iconColor: Constants.red,
                    iconSize: broadcastManager.sessionIsRunning ? 30 : 43,
                    backgroundColor: .white,
                    borderColor: .clear,
                    disabled: !broadcastManager.canStartSession
                )
            }
        }
        .transition(.move(edge: .bottom))
    }
    
    var body: some View {
        let drag = DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded(onDragEnded)
        
        return ZStack {
            VStack {}
                .frame(height: cardHeight + 200)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(drag)
            VStack {
                HStack {
                    streamControlButtons()
                        .simultaneousGesture(drag)
                }
                .padding(.bottom, 25)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .cornerRadius(20)
    }
}

struct ControlButton: View {
    var title: String
    var action: () -> Void
    var icon: String
    var iconColor: Color = .white
    var iconSize: CGFloat = 22
    var backgroundColor: Color = Constants.backgroundButton
    var borderColor: Color = Color.clear
    var disabled: Bool = false

    var body: some View {
        Button(action: {
            action()
        }) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: iconSize)
                        .stroke(borderColor, lineWidth: 2)
                        .frame(width: 52, height: 52)
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .foregroundColor(.white)
            }
            .opacity(disabled ? 0.2 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .disabled(disabled)
        .transition(.opacity)
        .padding(10)
    }
}
