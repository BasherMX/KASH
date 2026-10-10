import SwiftUI
import UIKit

// MARK: - Keyboard Dismiss Utilities (Solo para la app principal KASH)
extension View {
    /// Permite descartar el teclado interactivamente y al hacer scroll o tap en espacios libres
    func dismissKeyboardOnTap() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}

extension UIApplication {
    static func endEditing() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
