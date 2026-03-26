//
//  Root.swift
//  Phmirror
//
//  Created by Aryan Rogye on 3/26/26.
//

#if os(iOS)
import SwiftUI
import SnapCore

enum Theme {
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.72)
}

struct Root: View {
    @StateObject private var viewModel = IOSClientViewModel()
    
    @State private var lastPoint: CGPoint?
    
    @State private var cursorPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var screenLastPoint: CGPoint?
    @State private var trackpadLastLocation: CGPoint?
    @State private var scrollLastLocation: CGPoint?
    
    var body: some View {
        ZStack {
            RootBackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    statusCard
                    controlsCard
                    streamCard
                    trackpadCard
                    scrollCard
                    keyboardCard
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 2)
            }
        }
    }
    
    private var headerCard: some View {
        PHMirrorHeader {
            viewModel.reconnect()
        }
    }
    
    private var statusCard: some View {
        PHMirrorStatusCard(
            viewModel: viewModel,
        )
    }
    
    private var controlsCard: some View {
        PHMirrorControlCard(
            viewModel: viewModel
        )
    }
    
    private var streamCard: some View {
        PHMirrorStreamCard(
            viewModel: viewModel,
            screenLastPoint: $screenLastPoint,
            cursorPosition: $cursorPosition,
            lastPoint: $lastPoint,
        )
    }
    
    private var trackpadCard: some View {
        PHMirrorTrackpadCard(
            viewModel: viewModel,
            trackpadLastLocation: $trackpadLastLocation,
            lastPoint: $lastPoint,
            cursorPosition: $cursorPosition,
        )
    }
    
    private var scrollCard: some View {
        PHMirrorScrollCard(
            viewModel: viewModel,
            scrollLastLocation: $scrollLastLocation,
        )
    }
    
    private var keyboardCard: some View {
        PHMirrorKeyboardCard(
            viewModel: viewModel,
        )
    }
}

struct PHMirrorKeyboardCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    var primaryText: Color {
        Theme.primaryText
    }
    var secondaryText: Color {
        Theme.secondaryText
    }
    
    @State private var keyboardDraft = ""

    var body: some View {
        PHMirrorPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Keyboard")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)
                    Spacer()
                    Text("Type + send")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                }
                
                HStack(spacing: 8) {
                    TextField("Type text", text: $keyboardDraft)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .foregroundStyle(primaryText)
                        .onSubmit {
                            sendKeyboardText()
                        }
                    
                    Button("Send") {
                        sendKeyboardText()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.16))
                    .foregroundStyle(primaryText)
                    .disabled(!viewModel.controlEnabled || keyboardDraft.isEmpty)
                }
                
                HStack(spacing: 8) {
                    quickKeyButton(title: "Esc", keyCode: 53)
                    quickKeyButton(title: "Tab", keyCode: 48)
                    quickKeyButton(title: "Return", keyCode: 36)
                    quickKeyButton(title: "Delete", keyCode: 51)
                }
                
                HStack(spacing: 8) {
                    quickKeyButton(title: "←", keyCode: 123)
                    quickKeyButton(title: "↑", keyCode: 126)
                    quickKeyButton(title: "↓", keyCode: 125)
                    quickKeyButton(title: "→", keyCode: 124)
                }
            }
        }
    }
    
    private func sendKeyboardText() {
        guard viewModel.controlEnabled else { return }
        let text = keyboardDraft
        guard !text.isEmpty else { return }
        viewModel.sendKeyboard(
            KeyboardEvent(
                kind: .text,
                text: text,
                keyCode: nil
            )
        )
        keyboardDraft = ""
    }
    
    private func quickKeyButton(title: String, keyCode: UInt16) -> some View {
        Button(title) {
            sendSpecialKey(keyCode)
        }
        .buttonStyle(.bordered)
        .tint(Color.white.opacity(0.16))
        .foregroundStyle(primaryText)
        .disabled(!viewModel.controlEnabled)
        .frame(maxWidth: .infinity)
    }
    
    private func sendSpecialKey(_ keyCode: UInt16) {
        guard viewModel.controlEnabled else { return }
        viewModel.sendKeyboard(
            KeyboardEvent(
                kind: .keyPress,
                text: nil,
                keyCode: keyCode
            )
        )
    }
}

struct PHMirrorScrollCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    @Binding var scrollLastLocation: CGPoint?
    var primaryText: Color {
        Theme.primaryText
    }
    var secondaryText: Color {
        Theme.secondaryText
    }

    var body: some View {
        PHMirrorPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Scroll")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)
                    Spacer()
                    Text("Drag to scroll")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                }
                
                scrollSurface
            }
        }
    }
    
    private var scrollSurface: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                
                Text("Use this zone for two-finger style scrolling")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(secondaryText)
                    .padding(.horizontal, 10)
            }
            .contentShape(Rectangle())
            .gesture(scrollGesture(in: size))
        }
        .frame(height: 92)
    }
    
    private func scrollGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard viewModel.controlEnabled else { return }
                
                if scrollLastLocation == nil {
                    scrollLastLocation = value.location
                    return
                }
                
                guard let last = scrollLastLocation else { return }
                scrollLastLocation = value.location
                guard size.width > 1, size.height > 1 else { return }
                
                let dx = value.location.x - last.x
                let dy = value.location.y - last.y
                guard abs(dx) > 0.1 || abs(dy) > 0.1 else { return }
                
                viewModel.sendScroll(
                    ScrollEvent(
                        deltaX: dx,
                        deltaY: dy
                    )
                )
            }
            .onEnded { _ in
                scrollLastLocation = nil
            }
    }
}

struct PHMirrorTrackpadCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    @Binding var trackpadLastLocation: CGPoint?
    @Binding var lastPoint: CGPoint?
    @Binding var cursorPosition: CGPoint
    
    var primaryText: Color {
        Theme.primaryText
    }
    var secondaryText: Color {
        Theme.secondaryText
    }
    private let trackpadSensitivity: CGFloat = 1.2

    
    var body: some View {
        PHMirrorPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Trackpad")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)
                    Spacer()
                    Text("Drag moves • Button clicks")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                    
                    Button {
                        viewModel.sendClick(atRawPoint: cursorPosition)
                    } label: {
                        Label("Click", systemImage: "cursorarrow.click")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.16))
                    .foregroundStyle(primaryText)
                    .disabled(!viewModel.controlEnabled)
                }
                
                trackpadSurface
            }
        }
    }
    
    private var trackpadSurface: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 5]))
                    .foregroundStyle(Color.white.opacity(0.20))
                
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                    path.move(to: CGPoint(x: 0, y: size.height * 0.5))
                    path.addLine(to: CGPoint(x: size.width, y: size.height * 0.5))
                }
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                
                Circle()
                    .fill(viewModel.controlEnabled ? Color.white : Color.gray)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.white.opacity(0.40), radius: 6)
                    .position(x: cursorPosition.x * size.width, y: cursorPosition.y * size.height)
            }
            .contentShape(Rectangle())
            .gesture(trackpadGesture(in: size))
        }
        .frame(height: 188)
    }
    
    private func trackpadGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if trackpadLastLocation == nil {
                    trackpadLastLocation = value.location
                    return
                }
                
                guard let last = trackpadLastLocation else { return }
                trackpadLastLocation = value.location
                
                guard size.width > 1, size.height > 1 else { return }
                
                let dx = (value.location.x - last.x) / size.width * trackpadSensitivity
                let dy = (value.location.y - last.y) / size.height * trackpadSensitivity
                
                let next = CGPoint(
                    x: min(max(cursorPosition.x + dx, 0), 1),
                    y: min(max(cursorPosition.y + dy, 0), 1)
                )
                
                cursorPosition = next
                lastPoint = next
                
                guard viewModel.controlEnabled else { return }
                viewModel.sendPointer(phase: .move, atRawPoint: next, primaryDown: false)
            }
            .onEnded { _ in
                trackpadLastLocation = nil
            }
    }
}

struct PHMirrorStreamCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    @Binding var screenLastPoint: CGPoint?
    @Binding var cursorPosition: CGPoint
    @Binding var lastPoint: CGPoint?
    
    var primaryText: Color {
        Theme.primaryText
    }
    var secondaryText: Color {
        Theme.secondaryText
    }

    
    var body: some View {
        PHMirrorPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Live Screen")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryText)
                    Spacer()
                    Text("Direct touch enabled")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                }
                
                screenSurface
            }
        }
    }
    
    private var screenSurface: some View {
        ZStack {
            if let image = viewModel.latestFrame {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                Text("Waiting for stream...")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(secondaryText)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(screenGesture(in: geo.size))
            }
        }
        .aspectRatio(streamAspectRatio, contentMode: .fit)
    }
    
    private var streamAspectRatio: CGFloat {
        let width = max(CGFloat(viewModel.frameInfo.width), 1)
        let height = max(CGFloat(viewModel.frameInfo.height), 1)
        return width / height
    }
    
    private func screenGesture(in containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let normalized = normalize(location: value.location, in: containerSize) else { return }
                
                if screenLastPoint == nil {
                    screenLastPoint = normalized
                    return
                }
                
                guard let last = screenLastPoint else { return }
                screenLastPoint = normalized
                
                let dx = normalized.x - last.x
                let dy = normalized.y - last.y
                
                let next = CGPoint(
                    x: min(max(cursorPosition.x + dx, 0), 1),
                    y: min(max(cursorPosition.y + dy, 0), 1)
                )
                
                lastPoint = next
                cursorPosition = next
                
                guard viewModel.controlEnabled else { return }
                viewModel.sendPointer(phase: .move, atRawPoint: next, primaryDown: false)
            }
            .onEnded { _ in
                screenLastPoint = nil
            }
    }
    
    private func normalize(location: CGPoint, in containerSize: CGSize) -> CGPoint? {
        let streamWidth = max(CGFloat(viewModel.frameInfo.width), 1)
        let streamHeight = max(CGFloat(viewModel.frameInfo.height), 1)
        let streamAspect = streamWidth / streamHeight
        
        let containerAspect = containerSize.width / max(containerSize.height, 1)
        
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        let xInset: CGFloat
        let yInset: CGFloat
        
        if containerAspect > streamAspect {
            displayHeight = containerSize.height
            displayWidth = displayHeight * streamAspect
            xInset = (containerSize.width - displayWidth) / 2
            yInset = 0
        } else {
            displayWidth = containerSize.width
            displayHeight = displayWidth / streamAspect
            xInset = 0
            yInset = (containerSize.height - displayHeight) / 2
        }
        
        guard location.x >= xInset,
              location.x <= xInset + displayWidth,
              location.y >= yInset,
              location.y <= yInset + displayHeight else {
            return nil
        }
        
        let x = (location.x - xInset) / displayWidth
        let y = (location.y - yInset) / displayHeight
        
        return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }
}

struct PHMirrorControlCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    var primaryText: Color {
        Theme.primaryText
    }

    var body: some View {
        PHMirrorPanel {
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    Toggle(viewModel.controlEnabled ? "Touch" : "Control Off", isOn: $viewModel.controlEnabled)
                    Toggle("Invert X", isOn: $viewModel.invertX)
                    Toggle("Invert Y", isOn: $viewModel.invertY)
                }
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(primaryText)
                
                HStack(spacing: 14) {
                    Picker("Video Scale", selection: $viewModel.videoScale) {
                        ForEach(VideoScale.allCases, id: \.self) { scale in
                            Text(scale.stringValue).tag(scale)
                        }
                    }
                    .onChange(of: viewModel.videoScale) {
                        viewModel.sendVideoScale(viewModel.videoScale)
                    }
                }
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(primaryText)
            }
        }
    }
}

struct PHMirrorStatusCard: View {
    
    @ObservedObject var viewModel: IOSClientViewModel
    
    var isReceivingFrames: Bool {
        viewModel.isReceivingFrames
    }
    
    var secondaryText: Color {
        Theme.secondaryText
    }

    var connectedPeersCount: Int {
        viewModel.connectedPeers.count
    }
    
    var connectionStatus: String {
        viewModel.connectionStatus
    }
    
    private var networkPhaseText: String {
        switch viewModel.networkPhase {
        case .idle:
            return "Idle"
        case .searching:
            return "Searching"
        case .inviting:
            return "Inviting"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        }
    }
    
    private var networkPhaseColor: Color {
        switch viewModel.networkPhase {
        case .connected:
            return .white
        case .searching, .inviting, .connecting:
            return .gray
        case .error:
            return .red
        case .idle, .disconnected:
            return secondaryText
        }
    }

    var body: some View {
        PHMirrorPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    statusPill(
                        title: networkPhaseText,
                        color: networkPhaseColor
                    )
                    statusPill(
                        title: isReceivingFrames ? "Stream Live" : "Stream Waiting",
                        color: isReceivingFrames ? .white : .gray
                    )
                    statusPill(
                        title: "Peers \(connectedPeersCount)",
                        color: secondaryText
                    )
                    Spacer()
                }
                
                Text(connectionStatus)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(secondaryText)
            }
        }
    }
    
    private func statusPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded))
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.40), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.85), lineWidth: 1))
            .foregroundStyle(color)
            .animation(.easeInOut(duration: 0.25), value: title)
    }

}

struct PHMirrorHeader: View {
    
    var onReconnect: () -> Void
    
    var primaryText: Color {
        Theme.primaryText
    }
    var secondaryText: Color {
        Theme.secondaryText
    }
    
    var body: some View {
        PHMirrorPanel {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(primaryText)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phmirror Remote")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(primaryText)
                    Text("Touch, trackpad, and click control")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                }
                
                Spacer()
                
                Button("Reconnect") {
                    onReconnect()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.16))
                .foregroundStyle(primaryText)
            }
        }
    }
}

#Preview {
    Root()
}


#endif
