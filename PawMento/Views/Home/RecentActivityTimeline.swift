import SwiftUI

struct RecentActivityTimeline: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent activity")
                    .font(.headlineSM)
                    .foregroundColor(.onBackground)
                
                Spacer()
                
                Button(action: {
                    // See full timeline action
                }) {
                    Text("See full timeline ›")
                        .font(.labelSM)
                        .foregroundColor(.secondary)
                }
            }
            
            ZStack(alignment: .topLeading) {
                // Vertical Line
                Rectangle()
                    .fill(Color.surfaceContainerHighest)
                    .frame(width: 2)
                    .padding(.leading, 19)
                    .padding(.vertical, 8)
                
                VStack(spacing: 20) {
                    TimelineItem(icon: "fork.knife", title: "Breakfast logged", time: "Today, 7:32am")
                    TimelineItem(icon: "pawprint.fill", title: "Walk logged", time: "Yesterday, 6:15pm")
                    TimelineItem(icon: "pill.fill", title: "Apoquel logged", time: "Yesterday, 7:30am")
                }
            }
        }
        .padding(20)
        .background(Color.surfaceContainerLowest)
        .cornerRadius(24)
        .warmShadow()
    }
}

struct TimelineItem: View {
    let icon: String
    let title: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.onPrimaryContainer)
                .frame(width: 40, height: 40)
                .background(Color.primaryContainer)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.surfaceContainerLowest, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.labelMD)
                    .foregroundColor(.onSurface)
                Text(time)
                    .font(.labelSM)
                    .foregroundColor(.outline)
            }
            .padding(.top, 4)
            
            Spacer()
        }
    }
}

#Preview {
    RecentActivityTimeline()
        .padding()
        .background(Color.background)
}
