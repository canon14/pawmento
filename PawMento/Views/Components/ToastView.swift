import SwiftUI

struct ToastView: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        VStack {
            Spacer()
            
            if let toast = toastManager.currentToast {
                HStack(spacing: 12) {
                    Text(toast.message)
                        .font(.bodyMD)
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 8)
                    
                    if let actionLabel = toast.actionLabel, let action = toast.action {
                        Button(action: {
                            action()
                            toastManager.dismiss()
                        }) {
                            Text(actionLabel)
                                .font(.labelSM)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primaryText) // Dark background for contrast
                .cornerRadius(AppRadius.input)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Give space for bottom nav
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .id(toast.id)
            }
        }
        // Prevents the toast container from blocking touches when hidden
        .allowsHitTesting(toastManager.currentToast != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast)
    }
}
