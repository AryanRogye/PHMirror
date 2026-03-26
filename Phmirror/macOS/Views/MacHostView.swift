#if os(macOS)

import SwiftUI

struct MacHostView: View {
    @ObservedObject var viewModel: MacHostViewModel
    @State private var pulse = false

    private let brandOrange = Color(red: 0.96, green: 0.58, blue: 0.28)
    private let brandOrangeSoft = Color(red: 1.00, green: 0.75, blue: 0.50)
    private let ink = Color(red: 0.20, green: 0.16, blue: 0.12)

    var body: some View {
        ZStack {
            // Background Layer
            backgroundView
            
            VStack(spacing: 24) {
                headerView
                
                mainStatusView
                
                controlActionsView
                
                detailsGridView
                
                Spacer(minLength: 0)
                
                footerView
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - Background Components
    
    private var backgroundView: some View {
        ZStack {
            // Subtle warm gradient
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.99, blue: 0.97),
                    Color(red: 1.00, green: 0.96, blue: 0.90),
                    Color(red: 1.00, green: 0.94, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background orbs
            Circle()
                .fill(brandOrange.opacity(0.12))
                .frame(width: 320)
                .blur(radius: 50)
                .offset(x: -160, y: -120)
                .scaleEffect(pulse ? 1.2 : 0.8)

            Circle()
                .fill(brandOrangeSoft.opacity(0.15))
                .frame(width: 280)
                .blur(radius: 40)
                .offset(x: 180, y: 160)
                .scaleEffect(pulse ? 0.8 : 1.2)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [brandOrange, brandOrangeSoft],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: brandOrange.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: "display.2")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Phmirror")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(ink)
                
                Text("Host Controller")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.55))
            }
            
            Spacer()
            
            Button {
                viewModel.stopHosting()
                viewModel.startHosting()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ink.opacity(0.7))
                    .padding(8)
                    .background(Circle().fill(ink.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Reconnect and Restart Host")
        }
    }

    // MARK: - Status
    
    private var mainStatusView: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(statusColor.opacity(0.15), lineWidth: 4)
                    .frame(width: 90, height: 90)
                
                // Pulsing glow
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 110, height: 110)
                    .blur(radius: 12)
                    .scaleEffect(pulse ? 1.15 : 0.9)
                
                // Orbiting dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .offset(y: -45)
                    .rotationEffect(.degrees(pulse ? 360 : 0))
                
                // Icon
                Image(systemName: statusIcon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .shadow(color: statusColor.opacity(0.2), radius: 4)
            }
            .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: pulse)
            
            VStack(spacing: 4) {
                Text(statusTitle)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(ink)
                
                Text(viewModel.connectionStatus)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Actions
    
    private var controlActionsView: some View {
        HStack(spacing: 16) {
            actionButton(
                title: viewModel.isHosting ? "Stop Host" : "Start Host",
                icon: viewModel.isHosting ? "stop.fill" : "play.fill",
                color: ink,
                isActive: viewModel.isHosting
            ) {
                if viewModel.isHosting {
                    viewModel.stopHosting()
                } else {
                    viewModel.startHosting()
                }
            }
            
            actionButton(
                title: viewModel.isSharing ? "Stop Share" : "Start Share",
                icon: viewModel.isSharing ? "video.fill" : "video.badge.plus",
                color: brandOrange,
                isActive: viewModel.isSharing
            ) {
                if viewModel.isSharing {
                    viewModel.stopSharing()
                } else {
                    viewModel.startSharing()
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? color : color.opacity(0.08))
            )
            .foregroundStyle(isActive ? .white : color)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Details
    
    private var detailsGridView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                detailCard(title: "Resolution", value: viewModel.lastFrameSizeText, icon: "aspectratio")
                detailCard(title: "Peers", value: "\(viewModel.connectedPeers.count)", icon: "person.2")
            }
            
            HStack(spacing: 12) {
                detailCard(title: "Connection", value: hostPhaseText, icon: "network")
                detailCard(title: "Sharing", value: sharingPhaseText, icon: "rectangle.badge.play")
            }
        }
    }

    private func detailCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(ink.opacity(0.45))
            
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(ink.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ink.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Footer
    
    private var footerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lastError = viewModel.lastError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.multicolor)
                    Text(lastError)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                }
                .foregroundStyle(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(brandOrange.opacity(0.8))
                
                Text("Grant Screen Recording and Accessibility permissions in System Settings for full functionality.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ink.opacity(0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Logic Computed Properties
    
    private var statusColor: Color {
        if viewModel.sharingPhase == .streaming { return .green }
        if viewModel.sharingPhase == .waitingForPicker { return brandOrange }
        if viewModel.hostPhase == .connected { return .blue }
        if viewModel.hostPhase == .error { return .red }
        if viewModel.hostPhase == .connecting || viewModel.hostPhase == .waitingForClient { return brandOrange }
        return ink.opacity(0.3)
    }

    private var statusIcon: String {
        if viewModel.sharingPhase == .streaming { return "antenna.radiowaves.left.and.right" }
        if viewModel.sharingPhase == .waitingForPicker { return "display.trianglebadge.exclamationmark" }
        if viewModel.hostPhase == .connected { return "link" }
        if viewModel.hostPhase == .error { return "exclamationmark.triangle" }
        if viewModel.hostPhase == .connecting || viewModel.hostPhase == .waitingForClient { return "dot.radiowaves.left.and.right" }
        return "power.circle"
    }

    private var statusTitle: String {
        switch viewModel.sharingPhase {
        case .streaming: return "Live Streaming"
        case .waitingForPicker: return "Pick Content"
        case .notSharing:
            switch viewModel.hostPhase {
            case .connected: return "Host Active"
            case .connecting: return "Connecting..."
            case .waitingForClient: return "Ready to Connect"
            case .error: return "Host Error"
            case .idle: return "Host Idle"
            }
        }
    }

    private var hostPhaseText: String {
        switch viewModel.hostPhase {
        case .idle: return "Idle"
        case .waitingForClient: return "Waiting"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .error: return "Error"
        }
    }

    private var sharingPhaseText: String {
        switch viewModel.sharingPhase {
        case .notSharing: return "Inactive"
        case .waitingForPicker: return "Setup..."
        case .streaming: return "Streaming"
        }
    }

    private var connectedPeersText: String {
        viewModel.connectedPeers.isEmpty ? "none" : viewModel.connectedPeers.joined(separator: ", ")
    }
}

#Preview {
    MacHostView(viewModel: MacHostViewModel())
        .frame(width: 460)
}

#endif
