import SwiftUI

struct ReminderPillView: View {
    let reminder: Reminder
    let onLogTapped: () -> Void
    var onEditTapped: (() -> Void)? = nil
    var onDeleteTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.sage.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text(emoji(for: reminder.categoryId))
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.ink900)
                
                Text(formatTime(reminder.time) + " • " + reminder.frequency.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.ink900.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onLogTapped) {
                Text("Log")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.sage)
                    .cornerRadius(16)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .ink900.opacity(0.04), radius: 8, x: 0, y: 4)
        .frame(width: 280) // Fixed width so it looks good in a horizontal scroll
        .contextMenu {
            if let onEdit = onEditTapped {
                Button(action: onEdit) {
                    Label("Edit Reminder", systemImage: "pencil")
                }
            }
            if let onDelete = onDeleteTapped {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Reminder", systemImage: "trash")
                }
            }
        }
    }
    
    private func emoji(for categoryId: String) -> String {
        guard let category = LogCategory(rawValue: categoryId) else { return "🔔" }
        return category.emoji
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
