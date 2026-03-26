//
//  PHMirrorPanel.swift
//  Phmirror
//
//  Created by Aryan Rogye on 3/26/26.
//

#if os(iOS)
import SwiftUI

struct PHMirrorPanel<Content: View>: View {
    var content: () -> Content
    private let panelFill = Color.white.opacity(0.00)
    private let panelStroke = Color.white.opacity(0.14)
    
    var body: some View {
        content()
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(panelFill)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(.clear)
                    .stroke(panelStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 8)
    }
}
#endif
