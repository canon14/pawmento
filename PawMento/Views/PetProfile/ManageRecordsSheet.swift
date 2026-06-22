import SwiftUI

struct ManageRecordsSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var petStore: PetStore
    
    private var formattedWeight: String {
        guard let kg = petStore.activePet?.weightKg else { return "Unknown" }
        let isMetric = Locale.current.measurementSystem == .metric
        if isMetric {
            return "\(Int(round(kg))) kg"
        } else {
            let lbs = kg * 2.20462
            return "\(Int(round(lbs))) lbs"
        }
    }
    
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
                            RecordRow(title: "Weight History", value: formattedWeight, subtitle: "Stable")
                            Divider()
                            RecordRow(title: "Allergies", value: "Chicken, Environmental", subtitle: nil)
                            Divider()
                            RecordRow(title: "Conditions", value: "Atopic dermatitis", subtitle: nil)
                        }
                        .background(Color.surface0)
                        .cornerRadius(AppRadius.md)
                        .padding(.horizontal, 24)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Record")
                            }
                            .font(.bodyMD)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cream)
                            .cornerRadius(AppRadius.input)
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
                    .font(.labelLG)
                Text(value)
                    .font(.bodySM)
                    .foregroundColor(.primaryText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondaryText)
                .font(.bodySM)
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    ManageRecordsSheet()
        .environmentObject(PetStore())
}
