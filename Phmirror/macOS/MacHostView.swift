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

            Circle()
                .fill(brandOrange.opacity(0.24))
                .frame(width: 220)
                .blur(radius: 28)
                .offset(x: -120, y: -150)
                .scaleEffect(pulse ? 1.1 : 0.9)

            Circle()
                .fill(brandOrangeSoft.opacity(0.30))
                .frame(width: 190)
                .blur(radius: 24)
                .offset(x: 140, y: 180)
                .scaleEffect(pulse ? 0.9 : 1.07)

            VStack(spacing: 12) {
                headerCard
                statusCard
                controlsCard
                diagnosticsCard
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            if !viewModel.isHosting {
                viewModel.startHosting()
            }

            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var headerCard: some View {
        panel {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(brandOrange.opacity(0.20))
                        .frame(width: 46, height: 46)
                    Image(systemName: "display.2")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(ink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Phmirror Host")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(ink)

                    Text("Menu bar streaming and control relay")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(ink.opacity(0.65))
                }

                Spacer()

                Button("Reconnect") {
                    viewModel.stopHosting()
                    viewModel.startHosting()
                }
                .buttonStyle(.bordered)
                .tint(ink)
            }
        }
    }

    private var statusCard: some View {
        panel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Live Status")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(ink.opacity(0.78))

                HStack(spacing: 8) {
                    statusChip(title: hostPhaseText, color: hostPhaseColor)
                    statusChip(title: sharingPhaseText, color: sharingPhaseColor)
                    statusChip(title: "Peers \(viewModel.connectedPeers.count)", color: ink.opacity(0.8))
                }

                Text(viewModel.connectionStatus)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.75))
                    .lineLimit(2)
            }
        }
    }

    private var controlsCard: some View {
        panel {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button(viewModel.isHosting ? "Stop Host" : "Start Host") {
                        if viewModel.isHosting {
                            viewModel.stopHosting()
                        } else {
                            viewModel.startHosting()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(ink)

                    Button(viewModel.isSharing ? "Stop Share" : "Start Share") {
                        if viewModel.isSharing {
                            viewModel.stopSharing()
                        } else {
                            viewModel.startSharing()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(brandOrange)

                    Spacer()
                }

                HStack {
                    Text("Frame: \(viewModel.lastFrameSizeText)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(ink.opacity(0.78))
                    Spacer()
                    Text("Peers: \(connectedPeersText)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(ink.opacity(0.58))
                        .lineLimit(1)
                }
            }
        }
    }

    private var diagnosticsCard: some View {
        panel {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(ink.opacity(0.78))

                if let lastError = viewModel.lastError {
                    Text(lastError)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.red.opacity(0.9))
                }

                Text("Grant Screen Recording + Accessibility in System Settings.")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ink.opacity(0.62))
            }
        }
    }

    private var connectedPeersText: String {
        viewModel.connectedPeers.isEmpty ? "none" : viewModel.connectedPeers.joined(separator: ",")
    }

    private var hostPhaseText: String {
        switch viewModel.hostPhase {
        case .idle:
            return "Host Idle"
        case .waitingForClient:
            return "Waiting"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .error:
            return "Host Error"
        }
    }

    private var hostPhaseColor: Color {
        switch viewModel.hostPhase {
        case .connected:
            return .green
        case .connecting, .waitingForClient:
            return .orange
        case .error:
            return .red
        case .idle:
            return ink.opacity(0.8)
        }
    }

    private var sharingPhaseText: String {
        switch viewModel.sharingPhase {
        case .notSharing:
            return "Share Off"
        case .waitingForPicker:
            return "Pick Display"
        case .streaming:
            return "Share Live"
        }
    }

    private var sharingPhaseColor: Color {
        switch viewModel.sharingPhase {
        case .streaming:
            return .green
        case .waitingForPicker:
            return .orange
        case .notSharing:
            return ink.opacity(0.8)
        }
    }

    private func statusChip(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(.caption2, design: .rounded))
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.72), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.8), lineWidth: 1))
            .foregroundStyle(color)
            .animation(.easeInOut(duration: 0.25), value: title)
    }

    private func panel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.76))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brandOrange.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#endif
