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
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text(emoji(for: reminder.categoryId))
                    .font(.headlineMD)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.labelLG)
                    .foregroundColor(.ink900)
                
                Text(formatTime(reminder.time) + " • " + reminder.frequency.rawValue)
                    .font(.caption)
                    .foregroundColor(.ink900.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onLogTapped) {
                Text("Log")
                    .font(.bodyXS)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primary)
                    .cornerRadius(AppRadius.md)
            }
        }
        .padding(12)
        .background(Color.surface0)
        .cornerRadius(AppRadius.md)
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
