#if os(iOS)

import SwiftUI

struct IOSClientView: View {
    @StateObject private var viewModel = IOSClientViewModel()

    @State private var lastPoint: CGPoint?

    @State private var cursorPosition = CGPoint(x: 0.5, y: 0.5)
    @State private var screenLastPoint: CGPoint?
    @State private var trackpadLastLocation: CGPoint?
    @State private var scrollLastLocation: CGPoint?
    @State private var keyboardDraft = ""

    @State private var controlEnabled = true
    @State private var invertX = false
    @State private var invertY = false
    @State private var ambientGlow = false

    private let trackpadSensitivity: CGFloat = 1.2

    private let pageTop = Color(red: 0.05, green: 0.05, blue: 0.06)
    private let pageBottom = Color(red: 0.11, green: 0.12, blue: 0.14)
    private let panelFill = Color.white.opacity(0.07)
    private let panelStroke = Color.white.opacity(0.14)
    private let primaryText = Color.white
    private let secondaryText = Color.white.opacity(0.72)
    private let accent = Color.gray
    private let dotPrimary = Color.white.opacity(0.20)
    private let dotSecondary = Color.gray.opacity(0.34)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    pageTop,
                    pageBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(dotPrimary)
                .frame(width: 260)
                .blur(radius: 40)
                .offset(x: -130, y: -220)
                .scaleEffect(ambientGlow ? 1.1 : 0.9)

            Circle()
                .fill(dotSecondary)
                .frame(width: 220)
                .blur(radius: 36)
                .offset(x: 150, y: 260)
                .scaleEffect(ambientGlow ? 0.9 : 1.08)

            ScrollView {
                VStack(spacing: 10) {
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
            .scrollIndicators(.hidden)
        }
        .onAppear {
            viewModel.start()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                ambientGlow = true
            }
        }
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: controlEnabled) { _, enabled in
            guard !enabled else { return }
            trackpadLastLocation = nil
            scrollLastLocation = nil
        }
    }

    private var headerCard: some View {
        panel {
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
                    viewModel.reconnect()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.16))
                .foregroundStyle(primaryText)
            }
        }
    }

    private var statusCard: some View {
        panel {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    statusPill(title: networkPhaseText, color: networkPhaseColor)
                    statusPill(title: viewModel.isReceivingFrames ? "Stream Live" : "Stream Waiting", color: viewModel.isReceivingFrames ? .white : .gray)
                    statusPill(title: "Peers \(viewModel.connectedPeers.count)", color: secondaryText)
                    Spacer()
                }

                Text(viewModel.connectionStatus)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(secondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var controlsCard: some View {
        panel {
            VStack(spacing: 8) {
                Toggle(controlEnabled ? "Control On" : "Control Off", isOn: $controlEnabled)
                    .toggleStyle(.switch)
                    .tint(accent)
                    .foregroundStyle(primaryText)

                HStack(spacing: 14) {
                    Toggle("Invert X", isOn: $invertX)
                    Toggle("Invert Y", isOn: $invertY)
                    Spacer()
                    Text("Screen touch = offset move")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(secondaryText)
                }
                .font(.caption)
                .foregroundStyle(primaryText)
            }
        }
    }

    private var streamCard: some View {
        panel {
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

    private var trackpadCard: some View {
        panel {
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
                        sendClick(atRawPoint: cursorPosition)
                    } label: {
                        Label("Click", systemImage: "cursorarrow.click")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.white.opacity(0.16))
                    .foregroundStyle(primaryText)
                    .disabled(!controlEnabled)
                }

                trackpadSurface
            }
        }
    }

    private var scrollCard: some View {
        panel {
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

    private var keyboardCard: some View {
        panel {
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
                    .disabled(!controlEnabled || keyboardDraft.isEmpty)
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

    private var streamAspectRatio: CGFloat {
        let width = max(CGFloat(viewModel.frameInfo.width), 1)
        let height = max(CGFloat(viewModel.frameInfo.height), 1)
        return width / height
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
                    .fill(controlEnabled ? Color.white : Color.gray)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.white.opacity(0.40), radius: 6)
                    .position(x: cursorPosition.x * size.width, y: cursorPosition.y * size.height)
            }
            .contentShape(Rectangle())
            .gesture(trackpadGesture(in: size))
        }
        .frame(height: 188)
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

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(panelFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 8)
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

                guard controlEnabled else { return }
                sendPointer(phase: .move, atRawPoint: next, primaryDown: false)
            }
            .onEnded { _ in
                screenLastPoint = nil
            }
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

                guard controlEnabled else { return }
                sendPointer(phase: .move, atRawPoint: next, primaryDown: false)
            }
            .onEnded { _ in
                trackpadLastLocation = nil
            }
    }

    private func scrollGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard controlEnabled else { return }

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

    private func sendClick(atRawPoint rawPoint: CGPoint) {
        guard controlEnabled else { return }
        sendPointer(phase: .down, atRawPoint: rawPoint, primaryDown: true)
        sendPointer(phase: .up, atRawPoint: rawPoint, primaryDown: false)
    }

    private func sendPointer(phase: PointerPhase, atRawPoint rawPoint: CGPoint, primaryDown: Bool) {
        let point = applyAxisAdjustments(to: rawPoint)
        viewModel.sendPointer(
            PointerEvent(
                x: point.x,
                y: point.y,
                phase: phase,
                isPrimaryButtonDown: primaryDown
            )
        )
    }

    private func sendKeyboardText() {
        guard controlEnabled else { return }
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

    private func sendSpecialKey(_ keyCode: UInt16) {
        guard controlEnabled else { return }
        viewModel.sendKeyboard(
            KeyboardEvent(
                kind: .keyPress,
                text: nil,
                keyCode: keyCode
            )
        )
    }

    private func quickKeyButton(title: String, keyCode: UInt16) -> some View {
        Button(title) {
            sendSpecialKey(keyCode)
        }
        .buttonStyle(.bordered)
        .tint(Color.white.opacity(0.16))
        .foregroundStyle(primaryText)
        .disabled(!controlEnabled)
        .frame(maxWidth: .infinity)
    }

    private func applyAxisAdjustments(to point: CGPoint) -> CGPoint {
        CGPoint(
            x: invertX ? 1 - point.x : point.x,
            y: invertY ? 1 - point.y : point.y
        )
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

#endif
