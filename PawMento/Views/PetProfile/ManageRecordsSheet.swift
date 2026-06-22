import SwiftUI

struct ManageRecordsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Manage Vital Records")
                            .font(.headlineMD)
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                        
                        // Mock list of records
                        VStack(spacing: 0) {
                            RecordRow(title: "Vaccinations", value: "Up to date", subtitle: "Next: Aug 14")
                            Divider()
                            RecordRow(title: "Weight History", value: "68 lbs", subtitle: "Stable")
                            Divider()
                            RecordRow(title: "Allergies", value: "Chicken, Environmental", subtitle: nil)
                            Divider()
                            RecordRow(title: "Conditions", value: "Atopic dermatitis", subtitle: nil)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Record")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cream)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Vital Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                    .font(.headlineMD)
                }
            }
        }
    }
}

struct RecordRow: View {
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.primaryText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondaryText)
                .font(.system(size: 14))
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    ManageRecordsSheet()
}
