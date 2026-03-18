//
//  NaNSafety.swift
//  DCC-Weekly-Activities
//
//  Global NaN guards for CoreGraphics and chart rendering
//

import Foundation
import CoreGraphics

extension Double {
    /// Returns the value if finite, otherwise returns 0.0
    /// Use this to prevent NaN or Infinity from reaching CoreGraphics
    var safeValue: Double {
        return self.isFinite ? self : 0.0
    }
    
    /// Converts to CGFloat safely, substituting 0 for NaN or Infinity
    var safeCGFloat: CGFloat {
        return CGFloat(self.isFinite ? self : 0.0)
    }
}

extension CGFloat {
    /// Returns the value if finite, otherwise returns 0.0
    var safeValue: CGFloat {
        return self.isFinite ? self : 0.0
    }
}

extension Optional where Wrapped == Double {
    /// Returns the wrapped value if it exists and is finite, otherwise 0.0
    var safeValue: Double {
        guard let value = self else { return 0.0 }
        return value.isFinite ? value : 0.0
    }
}

extension Optional where Wrapped == CGFloat {
    /// Returns the wrapped value if it exists and is finite, otherwise 0.0
    var safeValue: CGFloat {
        guard let value = self else { return 0.0 }
        return value.isFinite ? value : 0.0
    }
}
