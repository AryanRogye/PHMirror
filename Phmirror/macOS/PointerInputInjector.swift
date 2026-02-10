#if os(macOS)

import AppKit
import CoreGraphics
import Foundation

enum PointerInputInjector {
    static func inject(_ event: PointerEvent) {
        guard let targetScreen = NSScreen.main else { return }

        let frame = targetScreen.frame
        let clampedX = min(max(event.x, 0), 1)
        let clampedY = min(max(event.y, 0), 1)

        // SnapCore frames are currently arriving rotated 180 degrees relative to
        // the iOS touch surface, so we mirror both axes before posting events.
        let x = frame.maxX - (clampedX * frame.width)
        let y = frame.minY + (clampedY * frame.height)
        let point = CGPoint(x: x, y: y)

        switch event.phase {
        case .down:
            post(type: .leftMouseDown, at: point)

        case .move:
            let type: CGEventType = event.isPrimaryButtonDown ? .leftMouseDragged : .mouseMoved
            post(type: type, at: point)

        case .up:
            post(type: .leftMouseUp, at: point)
        }
    }

    private static func post(type: CGEventType, at point: CGPoint) {
        guard let cgEvent = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }

        cgEvent.post(tap: .cghidEventTap)
    }

    static func injectScroll(_ event: ScrollEvent) {
        let vertical = Int32(max(min((-event.deltaY * 2.2).rounded(), 120), -120))
        let horizontal = Int32(max(min((event.deltaX * 2.2).rounded(), 120), -120))

        guard vertical != 0 || horizontal != 0 else { return }
        guard let cgEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: vertical, wheel2: horizontal, wheel3: 0) else {
            return
        }

        cgEvent.post(tap: .cghidEventTap)
    }

    static func injectKeyboard(_ event: KeyboardEvent) {
        switch event.kind {
        case .text:
            guard let text = event.text, !text.isEmpty else { return }
            postText(text)

        case .keyPress:
            guard let keyCode = event.keyCode else { return }
            postKeyPress(keyCode: CGKeyCode(keyCode))
        }
    }

    private static func postText(_ text: String) {
        let utf16 = Array(text.utf16)
        guard !utf16.isEmpty else { return }

        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return
        }

        down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private static func postKeyPress(keyCode: CGKeyCode) {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            return
        }

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

#endif
