import UIKit

protocol ScrollableDrawerContent {
    var scrollViewDelegate: UIScrollViewDelegate? { get set }

    func scrollToTop()
}
