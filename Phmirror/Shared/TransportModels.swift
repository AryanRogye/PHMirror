import Foundation

enum WirePacketType: UInt8 {
    case frame = 1
    case pointer = 2
    case frameInfo = 3
    case scroll = 4
    case keyboard = 5
}

enum PointerPhase: String, Codable {
    case down
    case move
    case up
}

struct PointerEvent: Codable {
    let x: Double
    let y: Double
    let phase: PointerPhase
    let isPrimaryButtonDown: Bool
}

struct ScrollEvent: Codable {
    let deltaX: Double
    let deltaY: Double
}

enum KeyboardEventKind: String, Codable {
    case text
    case keyPress
}

struct KeyboardEvent: Codable {
    let kind: KeyboardEventKind
    let text: String?
    let keyCode: UInt16?
}

struct FrameInfo: Codable {
    let width: Int
    let height: Int
}
