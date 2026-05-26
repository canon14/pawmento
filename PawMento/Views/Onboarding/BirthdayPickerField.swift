import SwiftUI

struct BirthdayPickerField: View {
    @Binding var selectedDateComponents: DateComponents?
    @State private var isExpanded: Bool = false
    
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    let months = Array(1...12)
    let years = Array(1990...Calendar.current.component(.year, from: Date())).reversed()
    
    var displayString: String {
        if let comps = selectedDateComponents, let m = comps.month, let y = comps.year {
            return String(format: "%02d / %d", m, y)
        }
        return "MM / YYYY"
    }
    
    var ageString: String? {
        guard let comps = selectedDateComponents, let y = comps.year else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - y
        return "~ \(max(0, age)) years old"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(displayString)
                        .font(.bodyMD)
                        .foregroundColor(selectedDateComponents == nil ? .tertiaryText : .primaryText)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isExpanded ? Color.warmTan : Color.warmSand, lineWidth: isExpanded ? 2 : 1)
                )
            }
            
            if isExpanded {
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") {
                            withAnimation {
                                selectedDateComponents = DateComponents(year: selectedYear, month: selectedMonth)
                                isExpanded = false
                            }
                        }
                        .font(.labelSemibold)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                    
                    HStack(spacing: 0) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(months, id: \.self) { month in
                                Text(String(format: "%02d", month)).tag(month)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        
                        Picker("Year", selection: $selectedYear) {
                            ForEach(Array(years), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 150)
                }
                .background(Color.surfaceContainerLow)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            if let age = ageString, !isExpanded {
                Text(age)
                    .font(.custom("PlusJakartaSans-Regular", size: 12))
                    .foregroundColor(.sage)
                    .padding(.top, 2)
            }
        }
    }
}
