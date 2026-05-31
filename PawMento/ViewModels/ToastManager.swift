import SwiftUI
import Combine

struct ToastMessage: Equatable {
    let id = UUID()
    let message: String
    let actionLabel: String?
    let action: (() -> Void)?
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class ToastManager: ObservableObject {
    @Published var currentToast: ToastMessage?
    private var dismissTask: Task<Void, Never>?
    
    func show(_ message: String, actionLabel: String? = nil, duration: TimeInterval = 3.0, action: (() -> Void)? = nil) {
        dismissTask?.cancel()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = ToastMessage(message: message, actionLabel: actionLabel, action: action)
        }
        
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeIn(duration: 0.2)) {
                self.currentToast = nil
            }
        }
    }
    
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.2)) {
            currentToast = nil
        }
    }
}
