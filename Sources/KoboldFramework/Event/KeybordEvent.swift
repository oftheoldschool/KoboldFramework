import Foundation
import UIKit

public enum KKeyboardEvent {
    case keyDown(KKeyboardEventKey)
    case keyUp(KKeyboardEventKey)
}

public struct KKeyboardEventKey {
    let keyCode: KKeyboardKeyCode
}

public enum KKeyboardKeyCode {
    case unknown
    
    // Letters
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z

    // Numbers
    case zero, one, two, three, four, five, six, seven, eight, nine

    // Function keys
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case f13, f14, f15, f16, f17, f18, f19, f20

    // Special keys
    case escape, `return`, tab, space, delete, backspace
    case shift, option, control, command
    case rightShift, rightOption, rightControl, rightCommand
    case capsLock, function

    // Arrow keys
    case upArrow, downArrow, leftArrow, rightArrow

    // Keypad
    case keypadZero, keypadOne, keypadTwo, keypadThree, keypadFour
    case keypadFive, keypadSix, keypadSeven, keypadEight, keypadNine
    case keypadDecimal, keypadPlus, keypadMinus, keypadMultiply, keypadDivide
    case keypadEnter, keypadEquals, keypadClear

    // Other keys
    case home, end, pageUp, pageDown
    case grave, minus, equal, leftBracket, rightBracket
    case backslash, semicolon, quote, comma, period, slash
}

import GameController
extension KKeyboardKeyCode {
    static func fromGCKeyCode(_ code: GCKeyCode) -> KKeyboardKeyCode {
        return switch code {
        // Letters
        case .keyA: .a
        case .keyB: .b
        case .keyC: .c
        case .keyD: .d
        case .keyE: .e
        case .keyF: .f
        case .keyG: .g
        case .keyH: .h
        case .keyI: .i
        case .keyJ: .j
        case .keyK: .k
        case .keyL: .l
        case .keyM: .m
        case .keyN: .n
        case .keyO: .o
        case .keyP: .p
        case .keyQ: .q
        case .keyR: .r
        case .keyS: .s
        case .keyT: .t
        case .keyU: .u
        case .keyV: .v
        case .keyW: .w
        case .keyX: .x
        case .keyY: .y
        case .keyZ: .z

        // Numbers
        case .zero: .zero
        case .one: .one
        case .two: .two
        case .three: .three
        case .four: .four
        case .five: .five
        case .six: .six
        case .seven: .seven
        case .eight: .eight
        case .nine: .nine

        // Function keys
        case .F1: .f1
        case .F2: .f2
        case .F3: .f3
        case .F4: .f4
        case .F5: .f5
        case .F6: .f6
        case .F7: .f7
        case .F8: .f8
        case .F9: .f9
        case .F10: .f10
        case .F11: .f11
        case .F12: .f12
        case .F13: .f13
        case .F14: .f14
        case .F15: .f15
        case .F16: .f16
        case .F17: .f17
        case .F18: .f18
        case .F19: .f19
        case .F20: .f20

        // Special keys
        case .escape: .escape
        case .returnOrEnter: .return
        case .tab: .tab
        case .spacebar: .space
        case .deleteOrBackspace: .delete
        case .deleteForward: .backspace
        case .leftShift: .shift
        case .leftAlt: .option
        case .leftControl: .control
        case .leftGUI: .command
        case .rightShift: .rightShift
        case .rightAlt: .rightOption
        case .rightControl: .rightControl
        case .rightGUI: .rightCommand
        case .capsLock: .capsLock
        case .application: .function

        // Arrow keys
        case .upArrow: .upArrow
        case .downArrow: .downArrow
        case .leftArrow: .leftArrow
        case .rightArrow: .rightArrow

        // Keypad
        case .keypad0: .keypadZero
        case .keypad1: .keypadOne
        case .keypad2: .keypadTwo
        case .keypad3: .keypadThree
        case .keypad4: .keypadFour
        case .keypad5: .keypadFive
        case .keypad6: .keypadSix
        case .keypad7: .keypadSeven
        case .keypad8: .keypadEight
        case .keypad9: .keypadNine
        case .keypadPeriod: .keypadDecimal
        case .keypadPlus: .keypadPlus
        case .keypadHyphen: .keypadMinus
        case .keypadAsterisk: .keypadMultiply
        case .keypadSlash: .keypadDivide
        case .keypadEnter: .keypadEnter
        case .keypadEqualSign: .keypadEquals

        // Other keys
        case .home: .home
        case .end: .end
        case .pageUp: .pageUp
        case .pageDown: .pageDown
        case .graveAccentAndTilde: .grave
        case .hyphen: .minus
        case .equalSign: .equal
        case .openBracket: .leftBracket
        case .closeBracket: .rightBracket
        case .backslash: .backslash
        case .semicolon: .semicolon
        case .quote: .quote
        case .comma: .comma
        case .period: .period
        case .slash: .slash

        default: .unknown
        }
    }
}
