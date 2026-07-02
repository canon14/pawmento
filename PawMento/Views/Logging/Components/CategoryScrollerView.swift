import SwiftUI

struct CategoryScrollerView: View {
    @Binding var selectedCategory: LogCategory?
    @State private var showingMoreCategories = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppStrings.QuickLog.whatHappened)
                .font(.labelSM)
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
                        VStack(spacing: 6) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                            Text("More")
                                .font(.labelMD)
                                .foregroundColor(.secondaryText)
                        }
                        .frame(width: 68, height: 80)
                        .background(Color.surface0.opacity(0.6))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
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
                    .font(isSelected ? .labelSM : .labelMD)
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
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(LogCategory.selectableCategories) { category in
                        let isSelected = selectedCategory == category
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedCategory = category
                            }
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            dismiss()
                        }) {
                            VStack(spacing: 6) {
                                Text(category.emoji)
                                    .font(.headlineLG)
                                    .scaleEffect(isSelected ? 1.1 : 1.0)
                                
                                Text(category.rawValue)
                                    .font(isSelected ? .labelSM : .labelSM)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(
                                isSelected
                                    ? LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(AppRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: isSelected ? Color.primary.opacity(0.2) : Color.black.opacity(0.02), radius: isSelected ? 6 : 3, x: 0, y: isSelected ? 3 : 1)
                            .foregroundColor(isSelected ? .white : .primaryText)
                        }
                        .buttonStyle(SquishyCardStyle())
                        .accessibilityLabel(category.rawValue)
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(20)
            }
            .background(Color.warmCream.ignoresSafeArea())
            .navigationTitle("All Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headlineLG)
                            .foregroundColor(.tertiaryText)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }
}
