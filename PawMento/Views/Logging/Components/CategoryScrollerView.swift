import SwiftUI

struct CategoryScrollerView: View {
    @Binding var selectedCategory: LogCategory?
    @State private var showingMoreCategories = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.QuickLog.whatHappened)
                .font(.labelSemibold)
                .foregroundColor(.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LogCategory.quickCategories) { category in
                        categoryChip(for: category)
                    }
                    
                    // More button
                    Button(action: {
                        showingMoreCategories = true
                    }) {
                        VStack(spacing: 8) {
                            Text("···")
                                .font(.headlineLG)
                                .padding(.top, 8)
                            Text("More")
                                .font(.labelMD)
                        }
                        .frame(width: 68, height: 80)
                        .background(
                            LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                        .foregroundColor(.primaryText)
                    }
                    .buttonStyle(SquishyCardStyle())
                }
            }
        }
        .sheet(isPresented: $showingMoreCategories) {
            FullCategoryGridView(selectedCategory: $selectedCategory)
                .presentationDetents([.medium, .large])
        }
    }
    
    @ViewBuilder
    private func categoryChip(for category: LogCategory) -> some View {
        let isSelected = selectedCategory == category
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedCategory = category
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            TelemetryEngine.shared.track(event: .quick_log_category_selected, properties: [
                "category": category.rawValue,
                "was_preselected": false
            ])
        }) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.headlineLG)
                    .padding(.top, 8)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(category.rawValue)
                    .font(isSelected ? .labelSemibold : .labelMD)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(width: 68, height: 80) // Slightly taller and wider for premium feel
            .background(
                isSelected ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.primary.opacity(0.3) : Color.black.opacity(0.02), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            .foregroundColor(isSelected ? .white : .primaryText)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(category.rawValue)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }
        .buttonStyle(SquishyCardStyle())
    }
}

struct FullCategoryGridView: View {
    @Binding var selectedCategory: LogCategory?
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(LogCategory.allCases) { category in
                        let isSelected = selectedCategory == category
                        
                        Button(action: {
                            withAnimation {
                                selectedCategory = category
                            }
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Text(category.emoji)
                                    .font(.headlineLG)
                                
                                Text(category.rawValue)
                                    .font(.labelSM)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(isSelected ? Color.primary : Color.surface0)
                            .cornerRadius(AppRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? Color.primary : Color.warmSand, lineWidth: 1)
                            )
                            .foregroundColor(isSelected ? .white : .primaryText)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmCream.ignoresSafeArea())
            .navigationTitle("All Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
