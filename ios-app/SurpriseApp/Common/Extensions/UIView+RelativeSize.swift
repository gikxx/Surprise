import UIKit

extension CGFloat {
    static func relativeHeight(_ percent: CGFloat) -> CGFloat {
        return UIScreen.main.bounds.height * percent
    }
    
    static func relativeWidth(_ percent: CGFloat) -> CGFloat {
        return UIScreen.main.bounds.width * percent
    }
}
