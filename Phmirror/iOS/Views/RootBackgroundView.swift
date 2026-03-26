//
//  RootBackgroundView.swift
//  Phmirror
//
//  Created by Aryan Rogye on 3/26/26.
//

#if os(iOS)
import SwiftUI

struct RootBackgroundView: View {
    
    private let pageTop = Color(red: 0.05, green: 0.05, blue: 0.06)
    private let pageBottom = Color(red: 0.11, green: 0.12, blue: 0.14)
    private let dotPrimary = Color.white.opacity(0.20)
    private let dotSecondary = Color.gray.opacity(0.34)
    @State private var ambientGlow = false
    
    var body: some View {
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
    }
}
#endif
