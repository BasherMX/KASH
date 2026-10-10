import SwiftUI
import UIKit

// MARK: - Keyboard Dismiss Utilities (Solo para la app principal KASH)
extension View {
    /// Permite descartar el teclado interactivamente al hacer scroll o al pulsar en cualquier espacio libre
    func dismissKeyboardOnTap() -> some View {
        self
            .scrollDismissesKeyboard(.interactively)
            .background(KeyboardDismissOverlay())
    }
}

extension UIApplication {
    static func endEditing() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Overlay invisible que detecta pulsaciones fuera del teclado sin interferir con botones ni campos de texto
struct KeyboardDismissOverlay: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = context.coordinator
            tap.name = "KASHKeyboardDismissTapGesture"

            let alreadyAttached = window.gestureRecognizers?.contains(where: { $0.name == "KASHKeyboardDismissTapGesture" }) ?? false
            if !alreadyAttached {
                window.addGestureRecognizer(tap)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func handleTap() {
            UIApplication.endEditing()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Si el toque fue sobre un campo de texto interactivo, permitir que el foco se coloque libremente
            var view = touch.view
            while let v = view {
                if v is UITextField || v is UITextView {
                    return false
                }
                view = v.superview
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
