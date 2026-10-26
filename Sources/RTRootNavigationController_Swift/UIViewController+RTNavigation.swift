import UIKit
import ObjectiveC

extension UIViewController: RTNavigationCompatible {}

extension UIViewController {
    var hasExplicitPopPreference: Bool {
        objc_getAssociatedObject(self, &RTAssociationKeys.disablePop) != nil
    }
    var navigationCustomization: RTNavigationCustomizing? { self as? RTNavigationCustomizing }
}
