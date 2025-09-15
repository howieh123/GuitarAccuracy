import Foundation

public enum Pattern {
    case quarter
    case eighth
    case eighthTriplet
    case sixteenth
    case sixteenthTriplet
}

public enum MetronomeMath {
    static func multiplier(for pattern: Pattern) -> Int {
        switch pattern {
        case .quarter: return 1
        case .eighth: return 2
        case .eighthTriplet: return 3
        case .sixteenth: return 4
        case .sixteenthTriplet: return 6
        }
    }

    static func ticksPerSecond(bpm: Int, pattern: Pattern) -> Double {
        let baseHz = Double(bpm) / 60.0
        return baseHz * Double(multiplier(for: pattern))
    }
}


