import SwiftUI

struct CategoryScrollerView: View {
    @Binding var selectedCategory: LogCategory?
    @State private var showingMoreCategories = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What happened?")
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
                                .font(.system(size: 24))
                                .padding(.top, 8)
                            Text("More")
                                .font(.labelMD)
                        }
                        .frame(width: 64, height: 76)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.warmSand, lineWidth: 1)
                        )
                        .foregroundColor(.primaryText)
                    }
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
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.system(size: 24))
                    .padding(.top, 8)
                
                Text(category.rawValue)
                    .font(.labelMD)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(width: 64, height: 76)
            .background(isSelected ? Color.warmTan : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.warmTan : Color.warmSand, lineWidth: 1)
            )
            .foregroundColor(isSelected ? .white : .primaryText)
            .shadow(color: isSelected ? Color.warmTan.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.0 : 0.98)
        }
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
                                    .font(.system(size: 24))
                                
                                Text(category.rawValue)
                                    .font(.labelSM)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(isSelected ? Color.warmTan : Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? Color.warmTan : Color.warmSand, lineWidth: 1)
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
